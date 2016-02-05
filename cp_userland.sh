#!/bin/bash

COLOR="\033[0m"
COLOR_RED="\033[31m"
COLOR_GREEN="\033[32m"

DEF_DESTDIR="/media/$USER/ROOT/"

# assume $1 is level when $# more then 1
log_msg() {
  level=
  if [ $# -gt 1 ]; then
    level=$1
    shift
  fi
  case "$level" in
  1)
    echo -e "${COLOR_RED}ERROR${COLOR}: $*"
    ;;
  *)
    echo -e "${COLOR_GREEN}$*${COLOR}"
    ;;
  esac
}

log_error() {
  log_msg 1 "$*"
}

log_debug() {
  log_msg "$*"
}

check_error() {
  [ "$?" = "0" ] && return 0
  log_error "$*"
  exit 1
}

destdir=$1
if [ -z "$destdir" ]; then
  echo -n "Enter destdir [$DEF_DESTDIR]: "
  read destdir
  [ -z "$destdir" ] && destdir=$DEF_DESTDIR
fi
[ -z "$destdir" ] && $(log_error "Unknown destdir"; exit 1)

log_debug "destdir: $destdir"

echo -n "Remove all in $destdir [y/N]: "
read ans && ans=`echo $ans | tr '[:lower:]' '[:upper:]'`
log_debug "ans: $ans"
if [ "$ans" = "Y" ]; then
  sudo rm -rf ${destdir}/{*,.[!.]*}
  check_error "Failed to remove all in $destdir"
fi

cp -a userland/* ${destdir}/

