#!/bin/bash
# $Id$
# shell utility for builder

UTIL_ANSICOLOR_NORMAL="\033[0m"
UTIL_ANSICOLOR_RED="\033[31m"
UTIL_ANSICOLOR_MEGENTA="\033[35m"
UTIL_ANSICOLOR_CYAN="\033[36m"

util_log() {
  COLOR=$UTIL_ANSICOLOR_NORMAL
  LEVEL=""

  LINE=""
  FUNC=""

  if [ -n "$BASH" ] && [ "$1" -ge "1" ] && [ "$1" -le "4" ]; then
    FUNC="${FUNCNAME[1]}"
    LINE="${BASH_LINENO[0]}"
  fi

  if [ "$1" -eq "1" ]; then
    LEVEL="ERROR"
    COLOR=$UTIL_ANSICOLOR_RED
  elif [ "$1" -eq "2" ]; then
    LEVEL="INFO"
    COLOR=$UTIL_ANSICOLOR_MEGENTA
  elif [ "$1" -eq "3" ]; then
    LEVEL="Debug"
    COLOR=$UTIL_ANSICOLOR_CYAN
  elif [ "$1" -eq "4" ]; then
    LEVEL="verbose"
  fi
  echo -ne "$COLOR"
  echo "${LEVEL} ${FUNC} #${LINE} $*"
  echo -ne "$UTIL_ANSICOLOR_NORMAL"
}

util_cp() {
  DEST=$1
  SRC=$2
  EX=$3
  
  let SRC_CNT=0
  for SRC1 in $SRC ; do
    let SRC_CNT=$SRC_CNT + 1
  done
  
  if [ "$SRC_CNT" -lt 1 ] ; then
    return 0
  elif [ "$SRC_CNT" -gt 1 ] ; then
    for SRC1 in "$SRC" ; do
      util_cp
    done
    return 0
  fi
  
  
  
    
}

[ -n "$1" ] && $*

