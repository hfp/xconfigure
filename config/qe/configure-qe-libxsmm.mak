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

# LIBXSMM (https://github.com/hfp/libxsmm)
#
#LIBXSMMROOT = /path/to/libxsmm

ifneq (,$(LIBXSMMROOT))
ifneq (,$(wildcard $(LIBXSMMROOT)/lib/libxsmmext.a))
  WRAP ?= 1
  ifeq (2,$(WRAP))
    LDFLAGS += -Wl,--wrap=dgemm_
  else
    LDFLAGS += -Wl,--wrap=sgemm_,--wrap=dgemm_
  endif
  #LDFLAGS += -Wl,--wrap=memalign,--wrap=malloc,--wrap=calloc,--wrap=realloc,--wrap=free
  LDFLAGS += -Wl,--export-dynamic
  #LD_LIBS += -lirc
  LD_LIBS += $(LIBXSMMROOT)/lib/libxsmm.a $(LIBXSMMROOT)/lib/libxsmmext.a $(LAPACK_LIBS)
  ifeq (,$(OPENMP))
  ifeq (sequential,$(MKL_OMPRTL))
    LD_LIBS += -liomp5
  endif
  endif
else
  $(info LIBXSMM library not found at $(LIBXSMMROOT))
endif
endif

