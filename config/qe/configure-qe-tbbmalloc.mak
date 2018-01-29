#############################################################################
# Copyright (c) 2014-2018, Intel Corporation                                #
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

