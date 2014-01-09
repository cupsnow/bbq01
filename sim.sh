#!/bin/bash
# $Id$

function getts() {
  _ret=`date +%s.%N`
}

# getcolor fg[style|bg]
function getcolor() {
  case $1 in
  red)
    _fg="31"
    shift
    ;;
  green)
    _fg="32"
    shift
    ;;
  blue)
    _fg="34"
    shift
    ;;
  cyan)
    _fg="36"
    shift
    ;;
  yellow)
    _fg="33"
    shift
    ;;
  megenta)
    _fg="35"
    shift
    ;;
  *)
    _fg="0"
    ;;
  esac
  
  _ret="\033[${_fg}m"
  
}

# log [level] message
# environment LOG_FILTER filter level to $LOG_FILTER
# environment LOG_FILE also output to file $LOG_FILE
# environment LOG_COLOR output with color
# ex: LOG_FILTER="debug info", this filter level==debug and level==info
function log() {
  # set level
  lvl=""
  if [ -n "$2" ] ; then
    if [ -n "$LOG_FILTER" ] && [ -n "`echo $LOG_FILTER | grep -io $1`" ] ; then
      return 0
    fi
    lvl="$1"
    shift
  fi
  if [ -z "$1" ] ; then
    return 0
  fi
  
  # set message and timestamp
  msg="$*"
  getts
  tm=$_ret
  msg2="$tm:$lvl:$msg"
  
  # output to file
  if [ -n "$LOG_FILE" ] ; then
    echo "$msg2" >> "$LOG_FILE"
  fi
  
  # output with color
  clr_fg=
  clr_reset=
  if [ -n "$LOG_COLOR" ] ; then
    if [ -n "`echo "error" | grep -io $lvl`" ] ; then
      getcolor red
    else
      getcolor green
    fi
    clr_fg=$_ret
    getcolor reset
    clr_reset=$_ret
  fi

  # output
  if [ -n "`echo "error" | grep -io $lvl`" ] ; then
    echo -e "${clr_fg}$msg2${clr_reset}" >&2
  else
    echo -e "${clr_fg}$msg2${clr_reset}"
  fi
}

function log_debug() {
  if [ -z "$1" ] ; then
    return 0
  fi
  
  log "debug" "$*"
}

# LOG_FILTER="debug"


QEMU_MEM="-m 128"
QEMU_MACH="-M versatilepb"
QEMU_TERM="-nographic"
BOOTARGS="-append 'root=/dev/ram console=ttyAMA0'"

CMD="qemu-system-arm $QEMU_MACH $QEMU_MEM $QEMU_TERM $BOOTARGS $* "
echo "CMD=$CMD"
eval $CMD
