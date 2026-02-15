#!/bin/sh

# Copyright 2026 Yury Gribov
#▫
# Use of this source code is governed by MIT license that can be
# found in the LICENSE.txt file.

set -eu
shift
source set_paths

check_tfs_tools

usage() {
  cat >&2 <<EOF
Usage: cv synch [OPTION]... [PATH | T@REL_PATH | $/XYZ_DEV/TFS_PATH]...

PATH is normal filesystem path, T@REL_PATH is path relative to
test root folder (prefixed with "T@"), TFS_PATH is full TFS path.

Options:
  -h, --help     Print help and exit.
  -x             Enable debug mode.
  -f, --force    Force re-synch even if test is already there.

Example:
  $ cv synch T@customer_apps/EEMBC/Legacy/conven
  $ cv synch ../conven2
EOF
  exit 1
}

ARGS=$(getopt -o 'hfx' --long 'help,force' -n $(basename $0) -- "$@")
eval set -- "$ARGS"

TF_GET="tf get /recursive"
while true; do
  case "$1" in
    -h | --help)
      usage
      ;;
    -x)
      set -x
      shift
      ;;
    -f | --force)
      TF_GET="$TF_GET /force"
      shift
      ;;
    --)
      shift
      break
      ;;
    -*)
      error "unknown option: $1"
      ;;
    *)
      error 'internal error'
      ;;
  esac
done

cwd_paths=
test_paths=
tfs_paths=

get_ws() {
  local ws
  ws=$(echo "${1#$XYZ_TFS_ROOT}" | sed 's!^\/\?\([^\/]*\).*!\1!')
  test -n "$ws"
  echo "$ws"
}

get_ws_path() {
  local p
  p=$(echo "${1#$XYZ_TFS_ROOT}" | sed 's!^\/\?[^\/]*\/!!')
  test -n "$p"
  echo "$p"
}

for p in $@; do
  echo "Synching $p..."
  if echo $p | grep -q '^T@'; then 
    p=$(echo $p | sed 's!^T@!!; s!^\/!!')
    test_paths="$test_paths $p"
  elif echo $p | grep -q '\$'; then
    p=$(echo $p | sed 's!^\$\/!!')
    tfs_paths="$tfs_paths $p"
  else
    cwd_paths="$cwd_paths $p"
  fi
done

if test -n "$test_paths"; then
  (cd $XYZ_QA_COMPILER/tests && $TF_GET $test_paths)
fi

if test -n "${XYZ_TASK:-}"; then
  tfs_paths_ws=$XYZ_TASK
else
  tfs_paths_ws=Common
fi

for p in $tfs_paths; do
  (cd $XYZ_TFS_ROOT/$tfs_paths_ws && $TF_GET $p)
done

for p in $cwd_paths; do
  # Split path to ws and intra-ws path
  if echo $p | grep -q '^\/'; then
    ws=$(get_ws "$p")
    ws_path=$(get_ws_path "$p")
    (cd $XYZ_TFS_ROOT/$ws && $TF_GET $ws_path)
  else
    $TF_GET $p
  fi
done
