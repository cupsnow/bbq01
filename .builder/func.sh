log() {
  LEVEL=
  FN=
  LN=
  if [ "$1" == "1" ]; then
    echo -ne "\033[31m" # red
    LEVEL="ERROR"
    shift
    FN=${FUNCNAME[2]}
    LN=${BASH_LINENO[1]}
  elif [ "$1" == "2" ]; then
    [ -n "$LOG_LEVEL" ] && [ "$LOG_LEVEL" -lt 2 ] && return 0
    echo -ne "\033[35m" # megenta
    LEVEL="INFO"
    shift
    FN=${FUNCNAME[2]}
    LN=${BASH_LINENO[1]}
  elif [ "$1" == "3" ]; then
    [ -n "$LOG_LEVEL" ] && [ "$LOG_LEVEL" -lt 3 ] && return 0
    echo -ne "\033[36m" # cyan
    LEVEL="Debug"
    shift
    FN=${FUNCNAME[2]}
    LN=${BASH_LINENO[1]}
  elif [ "$1" == "4" ]; then
    [ -n "$LOG_LEVEL" ] && [ "$LOG_LEVEL" -lt 4 ] && return 0
    echo -ne "\033[0m" # normal
    LEVEL="verbose"
    shift
    FN=${FUNCNAME[2]}
    LN=${BASH_LINENO[1]}
  else
    echo -ne "\033[0m" # normal
  fi  
  echo "${LEVEL} ${FN} #${LN} $*"
  echo -ne "\033[0m"
}

log_error() {
  log 1 "$*"
}

log_info() {
  log 2 "$*"
}

log_debug() {
  log 3 "$*"
}

log_verbose() {
  log 4 "$*"
}
