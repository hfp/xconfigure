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

# TBB runtime made for oldest/latest supported GCC
TBBGCC_OLD ?= 1
# ultimately disable/enable Intel TBB's malloc proxy
TBBMALLOC ?= 0

ifneq (0,$(TBBMALLOC))
  ifneq (,$(TBBROOT))
    GCC = $(notdir $(shell which gcc 2> /dev/null))
    ifneq (,$(GCC))
      GCC_VERSION_STRING = $(shell $(GCC) --version 2> /dev/null | head -n1 | sed "s/..* \([0-9][0-9]*\.[0-9][0-9]*\.*[0-9]*\)[ \S]*.*/\1/")
      GCC_VERSION_MAJOR = $(shell echo "$(GCC_VERSION_STRING)" | cut -d"." -f1)
      GCC_VERSION_MINOR = $(shell echo "$(GCC_VERSION_STRING)" | cut -d"." -f2)
      GCC_VERSION_PATCH = $(shell echo "$(GCC_VERSION_STRING)" | cut -d"." -f3)
      TBBLIBDIR = $(TBBROOT)/lib/intel64/gcc$(GCC_VERSION_MAJOR).$(GCC_VERSION_MINOR)
      TBBMALLOCLIB = $(wildcard $(TBBLIBDIR)/libtbbmalloc_proxy.so)
    endif
    ifeq (,$(TBBMALLOCLIB))
      ifneq (0,$(TBBGCC_OLD))
        TBBGCCDIR = $(shell ls -1 "$(TBBROOT)/lib/intel64" | tr "\n" " " | cut -d" " -f1)
      else
        TBBGCCDIR = $(shell ls -1 "$(TBBROOT)/lib/intel64" | tr "\n" " " | rev | cut -d" " -f2 | rev)
      endif
      TBBLIBDIR = $(TBBROOT)/lib/intel64/$(TBBGCCDIR)
      TBBMALLOCLIB = $(wildcard $(TBBLIBDIR)/libtbbmalloc_proxy.so)
    endif
    ifneq (,$(TBBMALLOCLIB))
      LIBS += $(TBBMALLOCLIB) $(TBBLIBDIR)/libtbbmalloc.so
      ifneq (1,$(TBBMALLOC)) # TBBMALLOC=2
        FCFLAGS += -heap-arrays
      endif
    endif
  endif
endif

