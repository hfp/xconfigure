#!/usr/bin/env python3
"""Index CP2K logs into an SQLite database and query it.

  info.py index [path ...]     # (re-)index changed logs (default: .)
  info.py sql "SELECT ..."     # run a query (tab-separated output)
  info.py schema               # show tables, columns, and views

The database (info.db) is a cache that can be rebuilt from the logs. It is
looked up from the current directory upward, or created in the current
directory (--db overrides). Paths are stored relative to the database.

Tables: runs (one row per log), timers (T I M I N G section), kernels (DBCSR
flops per kernel), env (environment printed by run.sh), files (all files seen).
"""

import argparse
import collections
import csv
import hashlib
import multiprocessing
import os
import re
import sqlite3
import sys

SCHEMA_VERSION = 1
SUFFIXES = (".txt", ".out", ".log")

SCHEMA = """
CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT);
CREATE TABLE files (path TEXT PRIMARY KEY, mtime INTEGER, size INTEGER, kind TEXT);
CREATE TABLE runs (
  path TEXT PRIMARY KEY, system TEXT, workload TEXT, variant TEXT, file TEXT,
  sha1 TEXT, cp2k_runs INTEGER, started TEXT, ended TEXT, host TEXT,
  version TEXT, revision TEXT, project TEXT, run_type TEXT, method TEXT,
  ranks INTEGER, threads INTEGER, nodes INTEGER, ranks_per_node INTEGER,
  nodes_src TEXT, cpu_model TEXT, launcher TEXT, mpi_kind TEXT, mpi_version TEXT,
  exe TEXT, libs TEXT, blas TEXT, gpu_api TEXT, compiler TEXT,
  acc INTEGER, devices INTEGER, devices_src TEXT, device_name TEXT,
  mm_driver TEXT, grid_backend TEXT, dbm INTEGER,
  complete INTEGER, wall REAL, cases_per_day INTEGER, energy REAL,
  scf_converged INTEGER, scf_method TEXT, scf_steps INTEGER,
  scf_mean REAL, scf_min REAL,
  dbcsr_flops REAL, dbcsr_blas REAL, dbcsr_smm REAL, dbcsr_acc REAL,
  marketing_flops REAL, dbcsr_mem_rank REAL, peak_mem_mib REAL, mem_total_kb REAL
);
CREATE TABLE timers (
  path TEXT, routine TEXT, calls INTEGER, asd REAL,
  self_avg REAL, self_max REAL, total_avg REAL, total_max REAL,
  PRIMARY KEY (path, routine)
);
CREATE TABLE kernels (
  path TEXT, m INTEGER, n INTEGER, k INTEGER, flops REAL,
  blas REAL, smm REAL, acc REAL, PRIMARY KEY (path, m, n, k)
);
CREATE TABLE env (path TEXT, key TEXT, value TEXT, PRIMARY KEY (path, key));
CREATE VIEW summary AS
  SELECT system, workload, file, project, nodes, ranks_per_node, threads,
         devices, wall, cases_per_day, started, version
  FROM runs WHERE complete ORDER BY system, workload, file;
"""

RE_STARTED = re.compile(r"PROGRAM STARTED AT\s+(\S.*?)\s*$")
RE_ENDED = re.compile(r"PROGRAM ENDED AT\s+(\S.*?)\s*$")
RE_HOST = re.compile(r"PROGRAM STARTED ON\s+(\S+)")
RE_VERSION = re.compile(r"CP2K\| version string:\s+(?:CP2K version\s+)?(\S.*?)\s*$")
RE_REVISION = re.compile(r"CP2K\| source code revision number:\s+(\S+)")
RE_GLOBAL = re.compile(r"^ GLOBAL\| (\S.*?)\s{2,}(\S.*?)\s*$")
RE_DBCSR = re.compile(r"^ DBCSR\| (\S.*?)\s{2,}(\S.*?)\s*$")
RE_ENV = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)=(.*)$")
RE_LAUNCHER = re.compile(r"(?:^|[\s/])(mpirun|mpiexec(?:\.hydra)?|srun|aprun)\s")
RE_NP = re.compile(r"\s-(?:np|n)\s+(\d+)")
RE_RPN = re.compile(
    r"\s-(?:perhost|ppn|npernode)\s+(\d+)"
    r"|--(?:npernode|ntasks-per-node)[= ](\d+)|ppr:(\d+):node"
)
RE_APRUN_RPN = re.compile(r"\s-N\s+(\d+)")
RE_IMPI = re.compile(r"MPI startup\(\): Intel\(R\) MPI Library, Version\s+(\S+)")
RE_IMPI_GPUS = re.compile(r"MPI startup\(\): GPUs\s*:\s*(\d+)")
RE_IMPI_TILES = re.compile(r"MPI startup\(\): (?:Stacks|Tiles)[^:]*:\s*(\d+)")
RE_OCLDEV = re.compile(r"INFO ACC/OpenCL: ndevices=\d+ device(\d+)=\"([^\"]*)\"")
RE_LDD = re.compile(r"^\s+(lib[^\s.]+)[^\s]*\.so")
RE_SCF = re.compile(
    r"^\s+(\d+)\s+((?:OT|P_Mix|Pulay|Broy|NoMix|Diag|TRS|Kerker)\S*(?: [A-Z]+)?)"
    r"\s+\S+\s+(\d+\.\d+)\s+-?\d+\.\d+\s+-?\d+\.\d+"
)
RE_ENERGY = re.compile(
    r"^ ENERGY\| Total FORCE_EVAL.*\s(-?\d+\.\d+(?:[EeDd][+-]?\d+)?)\s*$"
)
RE_PEAKMEM = re.compile(r"MEMORY\| Estimated peak process memory \[MiB\]\s+(\d+)")
RE_MEMTOTAL = re.compile(r"MEMORY\| MemTotal\s+(\d+)")
RE_FLOPS_KERNEL = re.compile(
    r"^ flops\s+(\d+) x\s+(\d+) x\s+(\d+)\s+(\d+)"
    r"(?:\s+([\d.]+)%\s+([\d.]+)%\s+([\d.]+)%)?"
)
RE_FLOPS_TOTAL = re.compile(
    r"^ flops total\s+(\S+)(?:\s+([\d.]+)%\s+([\d.]+)%\s+([\d.]+)%)?"
)
RE_MARKETING = re.compile(r"^ marketing flops\s+(\S+)")
RE_DBCSR_MEM = re.compile(r"^ max memory usage/rank\s+(\S+)")
RE_NAME_NODES = re.compile(r"^(?:(\d+)(?:x\d+)+|(\d+)n|n(\d+))$")
RE_NAME_NODES2 = re.compile(r"(\d+)_nodes")


def to_float(text):
    """Number from CP2K output (Fortran D-exponent included), or None."""
    try:
        return float(text.replace("D", "E").replace("d", "e"))
    except (AttributeError, ValueError):
        return None


def nodes_from_name(name):
    """Node-count from a file name (e.g., 4x16, 4n, n4, or 4_nodes), or None."""
    result = None
    match = RE_NAME_NODES2.search(name)
    if match:
        result = int(match.group(1))
    else:
        for token in re.split(r"[_.-]", name):
            match = RE_NAME_NODES.match(token)
            if match:
                result = int(next(g for g in match.groups() if g))
                break
    return result


def classify_libs(libs):
    """BLAS, GPU API, compiler runtime, and MPI flavor from library names."""
    blas = gpu = compiler = mpi = None
    for prefix, name in (
        ("libmkl_", "mkl"),
        ("libopenblas", "openblas"),
        ("libsci", "libsci"),
        ("libblis", "blis"),
        ("libarmpl", "armpl"),
        ("libblas", "blas"),
    ):
        if any(lib.startswith(prefix) for lib in libs):
            blas = name
            break
    apis = []
    for prefixes, name in (
        (("libOpenCL",), "opencl"),
        (("libcudart", "libcublas", "libcuda"), "cuda"),
        (("libamdhip64", "libhipblas"), "hip"),
        (("libze_loader",), "levelzero"),
    ):
        if any(lib.startswith(prefixes) for lib in libs):
            apis.append(name)
    if apis:
        gpu = ",".join(apis)
    if "libgfortran" in libs:
        compiler = "gnu"
    elif "libifcore" in libs or "libifport" in libs:
        compiler = "intel"
    elif any(lib.startswith(("libflang", "libpgf90", "libnvf")) for lib in libs):
        compiler = "llvm/nvhpc"
    if any(lib.startswith(("libmpich_cray", "libmpi_cray")) for lib in libs):
        mpi = "cray"
    elif "libmpich" in libs or "libmpichfort" in libs:
        mpi = "mpich"
    elif "libopen-pal" in libs or "libmpi_mpifh" in libs:
        mpi = "openmpi"
    return blas, gpu, compiler, mpi


def parse(path):
    """Parse a log; returns (sha1, run, timers, kernels, env) or None."""
    with open(path, "rb") as file:
        data = file.read()
    if b"CP2K| version string" not in data and b" GLOBAL| " not in data:
        return None
    sha1 = hashlib.sha1(data).hexdigest()
    run, glob, dbcsr = {}, {}, {}
    timers, kernels, env, libs, devs = [], [], {}, set(), collections.Counter()
    scf = collections.Counter()
    scf_times, ldd_lines, launcher = [], False, None
    impi_gpus = impi_tiles = None
    banner = section = None
    cp2k_runs = converged = unconverged = 0
    for line in data.decode("utf-8", "replace").splitlines():
        if "PROGRAM STARTED AT" in line:
            cp2k_runs += 1
            banner = True
            match = RE_STARTED.search(line)
            if match and 1 == cp2k_runs:
                run["started"] = match.group(1)
            continue
        if not banner:  # preamble written by run.sh and the MPI launcher
            if line.startswith("EXE: "):
                run["exe"] = line[5:].strip()
                ldd_lines = True
                continue
            if ldd_lines:  # indented lines printed by ldd
                if line[:1].isspace() and line.strip():
                    match = RE_LDD.match(line)
                    if match:
                        libs.add(match.group(1))
                    continue
                ldd_lines = False
            match = RE_ENV.match(line)
            if match:
                env.setdefault(match.group(1), match.group(2))
                continue
            if launcher is None and "cp2k" in line:
                match = RE_LAUNCHER.search(line)
                if match:
                    launcher = line.strip()
                    run["launcher"] = match.group(1)
        if "MPI startup()" in line:
            match = RE_IMPI.search(line)
            if match:
                run.setdefault("mpi_version", match.group(1))
            match = RE_IMPI_GPUS.search(line)
            if match and impi_gpus is None:
                impi_gpus = int(match.group(1))
            match = RE_IMPI_TILES.search(line)
            if match and impi_tiles is None:
                impi_tiles = int(match.group(1))
            continue
        if line.startswith("INFO ACC/OpenCL: ndevices"):
            match = RE_OCLDEV.match(line)
            if match:
                devs[match.group(1)] += 1
                name = re.sub(r"\s*\[0x[0-9a-fA-F]+\]$", "", match.group(2))
                run.setdefault("device_name", name)
            continue
        if 1 < cp2k_runs:  # only the first run of a log
            match = RE_ENDED.search(line)
            if match and "ended" not in run:
                run["ended"] = match.group(1)
            continue
        if section == "dbcsr":
            match = RE_FLOPS_KERNEL.match(line)
            if match:
                kernels.append(
                    tuple(int(g) for g in match.groups()[:3])
                    + (to_float(match.group(4)),)
                    + tuple(to_float(g) for g in match.groups()[4:])
                )
                continue
            match = RE_FLOPS_TOTAL.match(line)
            if match:
                run["dbcsr_flops"] = to_float(match.group(1))
                run["dbcsr_blas"] = to_float(match.group(2))
                run["dbcsr_smm"] = to_float(match.group(3))
                run["dbcsr_acc"] = to_float(match.group(4))
                continue
            match = RE_MARKETING.match(line)
            if match:
                run["marketing_flops"] = to_float(match.group(1))
                continue
            match = RE_DBCSR_MEM.match(line)
            if match:
                run["dbcsr_mem_rank"] = to_float(match.group(1))
                section = "dbcsr_done"
                continue
        elif section == "timing":
            tokens = line.split()
            if not tokens:
                if timers:
                    section = "timing_done"
                continue
            if 7 == len(tokens) and tokens[1].isdigit():
                values = [to_float(t) for t in tokens[2:]]
                if None not in values:
                    timers.append((tokens[0], int(tokens[1])) + tuple(values))
                    if "CP2K" == tokens[0]:
                        run["wall"] = values[3]  # total average (like info.sh)
            elif timers and tokens[0].startswith("-"):
                section = "timing_done"
            continue
        if "DBCSR STATISTICS" in line and section is None:
            section = "dbcsr"
        elif "T I M I N G" in line and section in (None, "dbcsr", "dbcsr_done"):
            section = "timing"
        elif line.startswith(" GLOBAL| "):
            match = RE_GLOBAL.match(line)
            if match:
                glob.setdefault(match.group(1), match.group(2))
        elif line.startswith(" DBCSR| "):
            match = RE_DBCSR.match(line)
            if match:
                dbcsr.setdefault(match.group(1), match.group(2))
        elif line.startswith(" CP2K| "):
            match = RE_VERSION.search(line)
            if match:
                run.setdefault("version", match.group(1))
            match = RE_REVISION.search(line)
            if match:
                run.setdefault("revision", match.group(1))
        elif "PROGRAM STARTED ON" in line:
            match = RE_HOST.search(line)
            if match:
                run.setdefault("host", match.group(1))
        elif "PROGRAM ENDED AT" in line:
            match = RE_ENDED.search(line)
            if match:
                run.setdefault("ended", match.group(1))
        elif "SCF run converged" in line:
            converged += 1
        elif "SCF run NOT converged" in line:
            unconverged += 1
        elif line.startswith(" ENERGY| Total FORCE_EVAL"):
            match = RE_ENERGY.match(line)
            if match:
                run["energy"] = to_float(match.group(1))
        elif line.startswith(" MEMORY| "):
            match = RE_PEAKMEM.search(line)
            if match:
                run["peak_mem_mib"] = to_float(match.group(1))
            match = RE_MEMTOTAL.search(line)
            if match:
                run.setdefault("mem_total_kb", to_float(match.group(1)))
        elif "DBM STATISTICS" in line:
            run["dbm"] = 1
        else:
            match = RE_SCF.match(line)
            if match:
                scf[match.group(2)] += 1
                scf_times.append(float(match.group(3)))
    run["cp2k_runs"] = cp2k_runs
    run["project"] = glob.get("Project name")
    run["run_type"] = glob.get("Run type")
    run["method"] = glob.get("Method name")
    run["cpu_model"] = glob.get("CPU model name")
    run["grid_backend"] = glob.get("Grid backend")
    run["mm_driver"] = dbcsr.get("Multiplication driver")
    ranks = glob.get("Total number of message passing processes")
    threads = glob.get("Number of threads for this process")
    run["ranks"] = int(ranks) if ranks and ranks.isdigit() else None
    run["threads"] = int(threads) if threads and threads.isdigit() else None
    run["dbm"] = run.get("dbm", 0)
    run["complete"] = int("wall" in run and "ended" in run)
    if run.get("wall"):
        run["cases_per_day"] = int(86400 / run["wall"])
    if converged or unconverged:
        run["scf_converged"] = int(0 == unconverged)
    if scf_times:
        run["scf_method"] = scf.most_common(1)[0][0]
        run["scf_steps"] = len(scf_times)
        run["scf_mean"] = sum(scf_times) / len(scf_times)
        run["scf_min"] = min(scf_times)
    # libraries and MPI flavor
    blas, gpu, compiler, mpi = classify_libs(libs)
    run.update(blas=blas, gpu_api=gpu, compiler=compiler)
    run["libs"] = ",".join(sorted(libs)) if libs else None
    if run.get("mpi_version"):
        mpi = "intel"
    elif mpi is None and launcher:
        if run["launcher"] == "aprun":
            mpi = "cray"
        elif re.search(r"--map-by|--report-bindings|--bind-to|-npernode", launcher):
            mpi = "openmpi"
        elif re.search(r"\s-(?:perhost|genvall|genv|bootstrap)\s", launcher):
            mpi = "intel"
    run["mpi_kind"] = mpi
    # layout: ranks per node and nodes
    nodes = glob.get("Number of distributed systems (nodes)")
    rpn = None
    if launcher:
        regex = RE_APRUN_RPN if "aprun" == run["launcher"] else RE_RPN
        match = regex.search(launcher)
        if match:
            rpn = int(next(g for g in match.groups() if g))
        if run["ranks"] is None:
            match = RE_NP.search(launcher)
            if match:
                run["ranks"] = int(match.group(1))
    ranks = run["ranks"] or 1
    if nodes and nodes.isdigit() and 0 < int(nodes):
        run["nodes"], run["nodes_src"] = int(nodes), "global"
    elif rpn:
        run["nodes"], run["nodes_src"] = max(ranks // rpn, 1), "launcher"
    else:
        named = nodes_from_name(os.path.basename(path))
        if named and named <= ranks:
            run["nodes"], run["nodes_src"] = named, "name"
        else:
            run["nodes"], run["nodes_src"] = 1, "assumed"
    run["ranks_per_node"] = max(ranks // run["nodes"], 1)
    # accelerators: devices in use per node
    run["acc"] = int(bool(dbcsr.get("ACC: Number of devices/node") or devs))
    count = source = None
    if impi_gpus or impi_tiles:  # Intel MPI's GPU pinning (one device per rank)
        count, source = max(impi_gpus or 0, impi_tiles or 0), "impi"
    elif devs:  # distinct devices selected by the ranks
        count, source = len(devs), "opencl"
    else:
        for key in ("ACC_OPENCL_DEVIDS", "ZE_AFFINITY_MASK", "CUDA_VISIBLE_DEVICES"):
            if env.get(key):
                count, source = len(env[key].split(",")), "env"
                break
        else:
            value = dbcsr.get("ACC: Number of devices/node")
            if value and value.isdigit():
                count, source = int(value), "dbcsr"
    if not run["acc"]:
        run["devices"] = 0
    elif count:  # ACC without a device-count leaves devices unknown (NULL)
        run["devices"] = min(count, run["ranks_per_node"])
        run["devices_src"] = source
    env = sorted(env.items())
    return sha1, run, timers, kernels, env


def parse_safe(path):
    """parse() for a worker process: exceptions become an error message."""
    try:
        result = (path, parse(path), None)
    except Exception as error:  # noqa: BLE001 (report and continue)
        result = (path, None, f"{type(error).__name__}: {error}")
    return result


def find_db(given):
    """Database file: given, or info.db from the current directory upward."""
    result = given
    if not result:
        directory = os.getcwd()
        while not result:
            candidate = os.path.join(directory, "info.db")
            parent = os.path.dirname(directory)
            if os.path.exists(candidate):
                result = candidate
            elif parent == directory:
                result = os.path.join(os.getcwd(), "info.db")
            else:
                directory = parent
    return os.path.abspath(result)


def open_db(path, rebuild=False):
    """Open (and create or upgrade) the database."""
    if rebuild and os.path.exists(path):
        os.remove(path)
    db = sqlite3.connect(path)
    version = None
    try:
        row = db.execute("SELECT value FROM meta WHERE key='schema'").fetchone()
        version = row[0] if row else None
    except sqlite3.OperationalError:
        pass
    if str(SCHEMA_VERSION) != version:
        db.close()
        if os.path.exists(path):
            os.remove(path)
        db = sqlite3.connect(path)
        db.executescript(SCHEMA)
        db.execute("INSERT INTO meta VALUES ('schema', ?)", (str(SCHEMA_VERSION),))
        db.commit()
    return db


def candidates(paths, root):
    """Log candidates under the paths as {relative path: (mtime, size)}."""
    result = {}
    for top in paths:
        for directory, dirs, files in os.walk(top):
            dirs[:] = sorted(d for d in dirs if not d.startswith("."))
            for name in files:
                if name.endswith(SUFFIXES):
                    full = os.path.join(directory, name)
                    stat = os.stat(full)
                    rel = os.path.relpath(full, root)
                    result[rel] = (stat.st_mtime_ns, stat.st_size)
    return result


def store(db, rel, parsed):
    """Replace the rows of a file."""
    for table in ("runs", "timers", "kernels", "env"):
        db.execute(f"DELETE FROM {table} WHERE path=?", (rel,))
    if parsed:
        sha1, run, timers, kernels, env = parsed
        parts = rel.split(os.sep)
        run.update(
            path=rel,
            sha1=sha1,
            system=parts[0] if 1 < len(parts) else None,
            workload=parts[1] if 2 < len(parts) else None,
            variant="/".join(parts[2:-1]) or None,
            file=parts[-1],
        )
        keys = sorted(run)
        db.execute(
            f"INSERT INTO runs ({','.join(keys)}) VALUES ({','.join('?' * len(keys))})",
            [run[key] for key in keys],
        )
        db.executemany(
            "INSERT OR IGNORE INTO timers VALUES (?,?,?,?,?,?,?,?)",
            [(rel,) + timer for timer in timers],
        )
        db.executemany(
            "INSERT OR IGNORE INTO kernels VALUES (?,?,?,?,?,?,?,?)",
            [(rel,) + kernel for kernel in kernels],
        )
        db.executemany("INSERT INTO env VALUES (?,?,?)", [(rel,) + kv for kv in env])


def cmd_index(args):
    """Index new or changed logs, and forget removed ones."""
    dbfile = find_db(args.db)
    root = os.path.dirname(dbfile)
    db = open_db(dbfile, args.rebuild)
    paths = args.paths or ["."]
    found = candidates(paths, root)
    known = {}
    for top in paths:
        prefix = os.path.relpath(os.path.abspath(top), root)
        prefix = "" if "." == prefix else prefix + os.sep
        for path, mtime, size in db.execute(
            "SELECT path, mtime, size FROM files WHERE path LIKE ?", (prefix + "%",)
        ):
            known[path] = (mtime, size)
    removed = [path for path in known if path not in found]
    changed = sorted(path for path, stat in found.items() if known.get(path) != stat)
    for path in removed:
        store(db, path, None)
        db.execute("DELETE FROM files WHERE path=?", (path,))
    nlogs = nerrors = 0
    with multiprocessing.Pool(args.jobs or None) as pool:
        jobs = [os.path.join(root, path) for path in changed]
        for count, (full, parsed, error) in enumerate(
            pool.imap_unordered(parse_safe, jobs, chunksize=4), 1
        ):
            rel = os.path.relpath(full, root)
            if error:
                nerrors += 1
                print(f"ERROR: {rel}: {error}", file=sys.stderr)
            else:
                store(db, rel, parsed)
                kind = "cp2k" if parsed else "other"
                nlogs += 1 if parsed else 0
                db.execute(
                    "INSERT OR REPLACE INTO files VALUES (?,?,?,?)",
                    (rel,) + found[rel] + (kind,),
                )
            if 0 == count % 200:
                db.commit()
                print(f"{count}/{len(changed)} files", file=sys.stderr)
    db.commit()
    print(
        f"{len(changed)} changed ({nlogs} logs, {nerrors} errors),"
        f" {len(removed)} removed: {dbfile}",
        file=sys.stderr,
    )
    db.close()
    return 1 if nerrors else 0


def cmd_sql(args):
    """Run a query and print its rows."""
    db = sqlite3.connect(find_db(args.db))
    cursor = db.execute(args.query)
    if cursor.description:
        rows = [[column[0] for column in cursor.description]]
        rows += [["" if v is None else v for v in row] for row in cursor]
        if args.csv or not sys.stdout.isatty():
            delimiter = "," if args.csv else "\t"
            csv.writer(sys.stdout, delimiter=delimiter, lineterminator="\n").writerows(
                rows
            )
        else:  # aligned columns
            text = [[str(value) for value in row] for row in rows]
            widths = [max(len(row[i]) for row in text) for i in range(len(text[0]))]
            for row in text:
                print("  ".join(v.ljust(w) for v, w in zip(row, widths)).rstrip())
    db.commit()
    db.close()
    return 0


def cmd_schema(args):
    """Print tables, views, and their columns."""
    db = sqlite3.connect(find_db(args.db))
    for kind, name in db.execute(
        "SELECT type, name FROM sqlite_master WHERE type IN ('table','view')"
    ):
        columns = [row[1] for row in db.execute(f"PRAGMA table_info({name})")]
        print(f"{kind} {name}: {', '.join(columns)}")
    db.close()
    return 0


def main():
    """Command line interface."""
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("--db", help="database file (default: info.db, see above)")
    sub = parser.add_subparsers(dest="command", required=True)
    index = sub.add_parser("index", help="index new or changed logs")
    index.add_argument("paths", nargs="*", help="directories (default: .)")
    index.add_argument("-j", "--jobs", type=int, help="parallel parsers (default: all)")
    index.add_argument("--rebuild", action="store_true", help="start from scratch")
    index.set_defaults(func=cmd_index)
    sql = sub.add_parser("sql", help="run an SQL query")
    sql.add_argument("query", help='e.g., "SELECT * FROM summary"')
    sql.add_argument("--csv", action="store_true", help="comma-separated output")
    sql.set_defaults(func=cmd_sql)
    schema = sub.add_parser("schema", help="show tables and views")
    schema.set_defaults(func=cmd_schema)
    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
