#!/bin/sh
#############################################################################
# Copyright (c) 2016-2017, Intel Corporation                                #
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

CHMOD=$(which chmod)
WGET=$(which wget)
CAT=$(which cat)
LS=$(which ls)
RM=$(which rm)

APPLICATION=$1
ARCHS=$2
KINDS=$3

if [ "" = "${CHMOD}" ] || [ "" = "${WGET}" ] || [ "" = "${CAT}" ] || [ "" = "${RM}" ]; then
  echo "Error: prerequisites not found!"
  exit 1
fi
if [ "" = "${APPLICATION}" ]; then
  echo "Please use: $0 <application-name>"
  exit 1
fi
if [ "0" != $(wget -S --spider https://github.com/hfp/xconfigure/blob/master/${APPLICATION}/README.md 2> /dev/null; echo $?) ]; then
  echo "Error: cannot find a recipe for application \"${APPLICATION}\"!"
  exit 1
fi

if [ "" = "${ARCHS}" ]; then
  ARCHS="snb hsw knl skx"
fi
if [ "" = "${KINDS}" ]; then
  KINDS="omp"
  for KIND in ${KINDS} ; do
    ${WGET} -N https://github.com/hfp/xconfigure/raw/master/${APPLICATION}/configure-${APPLICATION}-${KIND}.sh
  done
  for ARCH in ${ARCHS} ; do
    ${WGET} -N https://github.com/hfp/xconfigure/raw/master/${APPLICATION}/configure-${APPLICATION}-${ARCH}.sh
    for KIND in ${KINDS} ; do
      ${WGET} -N https://github.com/hfp/xconfigure/raw/master/${APPLICATION}/configure-${APPLICATION}-${ARCH}-${KIND}.sh
    done
  done
  ${WGET} -N https://github.com/hfp/xconfigure/raw/master/${APPLICATION}/configure-${APPLICATION}.sh
else
  for ARCH in ${ARCHS} ; do
    for KIND in ${KINDS} ; do
      ${WGET} -N https://github.com/hfp/xconfigure/raw/master/${APPLICATION}/configure-${APPLICATION}-${ARCH}-${KIND}.sh
    done
  done
  ${WGET} -N https://github.com/hfp/xconfigure/raw/master/${APPLICATION}/configure-${APPLICATION}.sh
fi

# attempt to get a list of non-default file names, and then download each file
${WGET} -N https://github.com/hfp/xconfigure/raw/master/${APPLICATION}/.filelist
if [ -e .filelist ]; then
  for FILE in $(${CAT} .filelist); do
    ${WGET} -N https://github.com/hfp/xconfigure/raw/master/${APPLICATION}/${FILE}
  done
  # cleanup list of file names
  ${RM} .filelist
fi

if [ "" != "$(${LS} -1 configure-${APPLICATION}* 2> /dev/null)" ]; then
  # make scripts executable
  ${CHMOD} +x *.sh 2> /dev/null
else
  # display reminder about build recipe
  echo
  echo "There is no configuration needed! Please read:"
  echo "https://github.com/hfp/xconfigure/tree/master/${APPLICATION}"
fi

