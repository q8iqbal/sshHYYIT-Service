#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
BACKEND_URL=''
NO_COLOR=0

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

    W_STR="$@"
    W_STR="${W_STR#*WHAT }"
  # check required params and arguments
  [[ -z "${BACKEND_URL}" ]] && die "Missing required parameter: param"
  [[ -z "$W_STR" ]] && die "Missing script arguments"

  return 0
}

parse_w() {
    W_STR_SLICE=($W_STR)
    W_STR_LEN=${#W_STR_SLICE}
    USERS_LEN=W_STR_LEN/8

    ip_server=$(ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1 | xargs)
    timestamp=$(date -u -d "${W_STR_SLICE[3]}" "+%F %T")

    users=()

    for ((i=0; i<$USERS_LEN; ++i)); do
        users+=('{ "user" : "'${W_STR_SLICE[0]}'", "ip_guest" : "'${W_STR_SLICE[2]}'", "timestamp": "'$timestamp'"}')
    done

    printf -v users_delimiter ',%s' "${users[@]}"
    users_delimiter=${users_delimiter:1}
    post_log "$ip_server" "$users_delimiter"
}

post_log(){
  curl --location --request POST "${BACKEND_URL}/connected-user"\
  --data-raw '{
      "ip_server": "'${1}'",
      "hostname": "'$(hostname)'",
      "users": [ '${2}' ]
  }'
}

parse_params "$@"
setup_colors
parse_w