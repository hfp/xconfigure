#!/usr/bin/env bash
###############################################################################
# Copyright (c) Intel Corporation - All rights reserved.                      #
# This file is part of the XCONFIGURE project.                                #
#                                                                             #
# For information on the license, see the LICENSE file.                       #
# Further information: https://github.com/hfp/xconfigure/                     #
# SPDX-License-Identifier: BSD-3-Clause                                       #
###############################################################################
# Hans Pabst (Intel Corp.)
###############################################################################

HERE=$(cd "$(dirname "$0")" && pwd -P)

# output directory
if [ "" != "$1" ]; then
  DOCDIR=$1
  shift
else
  DOCDIR=.
fi

# documentation file
HEREDIR=$(basename "${HERE}")
#TEXFILE=$(mktemp fileXXXXXX.tex)
TEXFILE=${HEREDIR}.tex
TEXENCG=utf-8

# dump pandoc template for latex, and adjust the template
pandoc -D latex \
| sed \
  -e 's/\(\\documentclass\[..*\]{..*}\)/\1\n\\pagenumbering{gobble}\n\\RedeclareSectionCommands[beforeskip=-1pt,afterskip=1pt]{subsection,subsubsection}/' \
  -e 's/\\usepackage{listings}/\\usepackage{listings}\\lstset{basicstyle=\\footnotesize\\ttfamily,showstringspaces=false}/' > \
  "${TEXFILE}"

# cleanup markup and pipe into pandoc using the template
( iconv -t ${TEXENCG} README.md && echo && \
  echo -e "# Applications\n\n" && \
  iconv -t ${TEXENCG} config/*/README.md | sed -e 's/^#/##/' && echo && \
  echo -e "# Appendix\n\n" && \
  iconv -t ${TEXENCG} config/cp2k/plan.md | sed -e 's/^#/##/' && echo \
) | sed \
  -e 's/<sub>/~/g' -e 's/<\/sub>/~/g' \
  -e 's/<sup>/^/g' -e 's/<\/sup>/^/g' \
  -e 's/\[\[..*\](..*)\]//g' \
  -e 's/\[!\[..*\](..*)\](..*)//g' \
| tee >( pandoc \
  --template="${TEXFILE}" --listings \
  -f gfm+implicit_figures+subscript+superscript \
  -V documentclass=scrartcl \
  -V title-meta="XCONFIGURE Documentation" \
  -V author-meta="Hans Pabst" \
  -V classoption=DIV=45 \
  -V linkcolor=black \
  -V citecolor=black \
  -V urlcolor=black \
  -o "${DOCDIR}/${HEREDIR}.pdf") \
| tee >( pandoc \
  -f gfm+implicit_figures+subscript+superscript \
  -o "${DOCDIR}/${HEREDIR}.html") \
| pandoc \
  -f gfm+implicit_figures+subscript+superscript \
  -o "${DOCDIR}/${HEREDIR}.docx"

# remove temporary file
if [ "${TEXFILE}" != "${HEREDIR}.tex" ]; then
  rm "${TEXFILE}"
fi
