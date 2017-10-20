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

BASENAME=$(which basename 2> /dev/null)
CHMOD=$(which chmod 2> /dev/null)
WGET=$(which wget 2> /dev/null)
CAT=$(which cat 2> /dev/null)
LS=$(which ls 2> /dev/null)
RM=$(which rm 2> /dev/null)

BASEURL=https://github.com/hfp/xconfigure/raw/master/config
ERROR_NOTFOUND=8
APPLICATION=$1
ARCHS=$2
KINDS=$3

if [ "" = "${CHMOD}" ] || [ "" = "${WGET}" ] || [ "" = "${CAT}" ] || [ "" = "${RM}" ]; then
  echo "Error: prerequisites not found!"
  exit 1
fi
WGET="${WGET} --no-check-certificate"

if [ "" = "${APPLICATION}" ]; then
  echo "Please use: $0 <application-name>"
  exit 1
fi
if [ "0" != $(${WGET} -S --spider ${BASEURL}/${APPLICATION}/README.md 2> /dev/null; echo $?) ]; then
  echo "Error: cannot find a recipe for application \"${APPLICATION}\"!"
  exit 1
fi

MSGBUFFER=$(mktemp .configure-XXXXXX.buf)
if [ "" = "${ARCHS}" ]; then
  ARCHS="snb hsw knl skx"
fi
if [ "" = "${KINDS}" ]; then
  KINDS="omp"
  for KIND in ${KINDS} ; do
    if [ "${ERROR_NOTFOUND}" != "$(${WGET} -N ${BASEURL}/${APPLICATION}/configure-${APPLICATION}-${KIND}.sh 2>${MSGBUFFER}; echo $?)" ]; then
      ${CAT} ${MSGBUFFER}
    fi
  done
  for ARCH in ${ARCHS} ; do
    if [ "${ERROR_NOTFOUND}" != "$(${WGET} -N ${BASEURL}/${APPLICATION}/configure-${APPLICATION}-${ARCH}.sh 2>${MSGBUFFER}; echo $?)" ]; then
      ${CAT} ${MSGBUFFER}
    fi
    for KIND in ${KINDS} ; do
      if [ "${ERROR_NOTFOUND}" != "$(${WGET} -N ${BASEURL}/${APPLICATION}/configure-${APPLICATION}-${ARCH}-${KIND}.sh 2>${MSGBUFFER}; echo $?)" ]; then
        ${CAT} ${MSGBUFFER}
      fi
    done
  done
  if [ "${ERROR_NOTFOUND}" != "$(${WGET} -N ${BASEURL}/${APPLICATION}/configure-${APPLICATION}.sh 2>${MSGBUFFER}; echo $?)" ]; then
    ${CAT} ${MSGBUFFER}
  fi
else
  for ARCH in ${ARCHS} ; do
    for KIND in ${KINDS} ; do
      if [ "${ERROR_NOTFOUND}" != "$(${WGET} -N ${BASEURL}/${APPLICATION}/configure-${APPLICATION}-${ARCH}-${KIND}.sh 2>${MSGBUFFER}; echo $?)" ]; then
        ${CAT} ${MSGBUFFER}
      fi
    done
  done
  if [ "${ERROR_NOTFOUND}" != "$(${WGET} -N ${BASEURL}/${APPLICATION}/configure-${APPLICATION}.sh 2>${MSGBUFFER}; echo $?)" ]; then
    ${CAT} ${MSGBUFFER}
  fi
fi

# attempt to get a list of non-default file names, and then download each file
if [ "${ERROR_NOTFOUND}" != "$(${WGET} -N ${BASEURL}/${APPLICATION}/.filelist 2>${MSGBUFFER}; echo $?)" ]; then
  ${CAT} ${MSGBUFFER}
fi
if [ -e .filelist ]; then
  for FILE in $(${CAT} .filelist); do
    ${WGET} -N ${BASEURL}/${APPLICATION}/${FILE}
  done
  # cleanup list of file names
  ${RM} .filelist
fi

# cleanup message buffer
${RM} ${MSGBUFFER}

if [ "" != "$(${LS} -1 configure-${APPLICATION}* 2> /dev/null)" ]; then
  # make scripts executable
  ${CHMOD} +x *.sh 2> /dev/null
else
  # display reminder about build recipe
  echo
  echo "There is no configuration needed! Please read:"
  echo "https://github.com/hfp/xconfigure/tree/master/config/${APPLICATION}"
fi

