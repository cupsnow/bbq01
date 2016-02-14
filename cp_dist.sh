#!/bin/bash

COLOR="\033[0m"
COLOR_RED="\033[31m"
COLOR_GREEN="\033[32m"

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

cp_dist() {
  srcdir=$1
  destdir=$2
    echo -n "Copy $srcdir to $destdir: [y/N]: "
  read cp_root && cp_root=`echo $cp_root | tr '[:upper:]' '[:lower:]'`
  if [ "$cp_root" = "y" ]; then
    echo -n "Erase all in $destdir [y/N]: "
    read rm_all && rm_all=`echo $rm_all | tr '[:upper:]' '[:lower:]'`
    if [ "$rm_all" = "y" ]; then
      echo "Erasing all in $destdir (might ask sudo password)"
      sudo rm -rf ${destdir}/{*,.[!.]*}
      check_error "Failed to remove all in $destdir"
    fi
    echo "Copying $srcdir to $destdir"
    cp -a ${srcdir}/* ${destdir}/
  fi
}

platform=`cat Makefile | sed -n -e "s/^\\s*PLATFORM\\s*=\\s*\(.*\)\\s*$/\\1/p"`
cp_dist "`pwd`/userland" "/media/$USER/ROOT"
cp_dist "`pwd`/dist/$platform" "/media/$USER/bbq01"
