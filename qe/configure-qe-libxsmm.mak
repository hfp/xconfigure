#############################################################################
# Copyright (c) 2017, Intel Corporation                                     #
# All rights reserved.                                                      #
#                                                                           #
# Redistribution and use in source and binary forms, with or without        #
# modification, are permitted provided that the following conditions        #
# are met:                                                                  #
# 1. Redistributions of source code must retain the above copyright         #
#    notice, this list of conditions and the following disclaimer.          #
# 2. Redistributions in binary form must reproduce the above copyright      #
#    notice, this list of conditions and the following disclaimer in the    #
#    documentation and/or other materials provided with the distribution.   #
# 3. Neither the name of the copyright holder nor the names of its          #
#    contributors may be used to endorse or promote products derived        #
#    from this software without specific prior written permission.          #
#                                                                           #
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS       #
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT         #
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR     #
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT      #
# HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,    #
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED  #
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR    #
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF    #
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING      #
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS        #
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.              #
#############################################################################
# Hans Pabst (Intel Corp.)
#############################################################################

# LIBXSMM (https://github.com/hfp/libxsmm)
#
#LIBXSMMROOT = /path/to/libxsmm
ifneq (0,$(LIBXSMM))
  ifeq (,$(strip $(LIBXSMMROOT)))
    ifneq (,$(wildcard ../libxsmm/Makefile))
      LIBXSMMROOT = ../libxsmm
    else ifneq (,$(wildcard $(HOME)/libxsmm/Makefile))
      LIBXSMMROOT = $(HOME)/libxsmm
    endif
  endif
endif

ifneq (,$(LIBXSMMROOT))
  LIBXSMM ?= 1
  ifneq (,$(OPENMP))
    OMP ?= 1
  endif
  OMP ?= 0
  ifneq (0,$(LIBXSMM))
    LIBXSMM_LIB = libxsmm/lib/libxsmm.a
    # enable additional use cases for LIBXSMM
    ifeq (1,$(shell echo $$((1 < $(LIBXSMM)))))
      DFLAGS += -D__LIBXSMM_TRANS
      # substitute "big" xGEMM calls with LIBXSMM
      ifeq (1,$(shell echo $$((2 < $(LIBXSMM)))))
        LIBS += libxsmm/lib/libxsmmext.a
        WRAP ?= 1
        ifeq (2,$(WRAP))
          LDFLAGS += -Wl,--wrap=dgemm_
        else
          LDFLAGS += -Wl,--wrap=sgemm_,--wrap=dgemm_
        endif
      else
        WRAP ?= 0
      endif
      # account for OpenMP-enabled wrapper routines
      ifeq (0,$(OMP))
        ifeq (1,$(MKL))
          LIBS += -liomp5
        else ifeq (0,$(MKL))
          LIBS += -liomp5
        endif
      endif
    else
      WRAP ?= 0
    endif
$(LIBXSMM_LIB): .state
	$(info ================================================================================)
	$(info Automatically enabled LIBXSMM $(shell $(LIBXSMMROOT)/scripts/libxsmm_utilities.py 2> /dev/null))
	$(info LIBXSMMROOT=$(LIBXSMMROOT))
	$(info ================================================================================)
	@$(MAKE) --no-print-directory -f $(LIBXSMMROOT)/Makefile \
		INCDIR=libxsmm/include \
		BLDDIR=libxsmm/build \
		BINDIR=libxsmm/bin \
		OUTDIR=libxsmm/lib \
touch-dummy: $(LIBXSMM_LIB)
    LIBS += $(LIBXSMM_LIB)
  endif
endif

