#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

usage() {
  cat << EOF # remove the space between << and EOF, this is due to web plugin issue
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-u] -u param_value arg1 [arg2...]

Bash script for preprocess ssh log and send it to api server

Available options:

-h, --help      Print this help and exit
-u, --url       Define api url to hit
EOF
  exit
}

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
}

setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
  else
    NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
  fi
}

msg() {
  echo >&2 -e "${1-}"
}

die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  msg "$msg"
  exit "$code"
}

parse_params() {
  # default values of variables set from params
  BACKEND_URL=''
  NO_COLOR=0

  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    -u | --url) # example named parameter
      BACKEND_URL="${2-}"
      shift
      ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  LOG_STR=($@)

  # check required params and arguments
  [[ -z "${BACKEND_URL}" ]] && die "Missing required parameter: param"
  [[ -z "$LOG_STR" ]] && die "Missing script arguments"

  return 0
}

parse_log() {
    status=""
    ip_guest=""

    case "${LOG_STR[5]}" in
    Invalid) 
        status="Failed" 
        ip_guest="${LOG_STR[9]}"
        username="${LOG_STR[7]}"
        ;;
    Failed) 
        status="Failed"
        ip_guest="${LOG_STR[10]}"
        username="${LOG_STR[8]}"
        ;;
    Accepted) 
        status="Connected" ;
        ip_guest="${LOG_STR[10]}"
        username="${LOG_STR[8]}"
        ;;
    -?*) exit ;;
    *) exit ;;
    esac

    ip_server=$(ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1 | xargs)
    hostname="${LOG_STR[3]}"
    timestamp=$(date -u -d "${LOG_STR[0]} ${LOG_STR[1]} ${LOG_STR[2]}" "+%F %T")
    post_log "$ip_server" "$hostname" "$ip_guest" "$username" "$timestamp" "$status"

    return 0
}

post_log(){
  curl --location --request POST ''${BACKEND_URL}'/log' \
  --data-raw '{
        "ip_server": "'${1}'",
        "hostname": "'${2}'",
        "ip_guest": "'${3}'",
        "username": "'${4}'",
        "timestamp": "'${5}'",
        "status": "'${6}'"
    }'
}

parse_params "$@"
setup_colors
parse_log