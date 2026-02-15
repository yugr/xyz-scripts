#!/bin/sh

# Copyright 2026 Yury Gribov
#▫
# Use of this source code is governed by MIT license that can be
# found in the LICENSE.txt file.

set -eu
shift
source set_paths

usage_short() {
  CMD=$(basename $0 .sh)
  cat >&2 <<EOF
Usage: cv copy-tools [OPT]... TASK [TARGET]...
For more info run \`cv help $CMD'
EOF
  exit 1
}

usage() {
  cat >&2 <<EOF
Usage: cv copy-tools [OPT]... TASK [TARGET]...

If TARGET is not specified, results for currently set core are loaded.

Available options:
  -h, --help   Print help and exit.
  -x           Enable debug mode.

Example:
  $ cv copy-tools v123_53
  $ cv copy-tools v123_53 r2
EOF
  ls -1 $XYZ_INSTALL_ROOT | sed 's/^/  /' >&2
  exit
}

ARGS=$(getopt -o 'hx' --long 'help' -n $(basename $0) -- "$@")
eval set -- "$ARGS"
while true; do
  case "$1" in
    -h | --help)
      usage
      ;;
    -x)
      set -x
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

if test $# = 0; then
  usage_short
fi

check_task_set

TASK=$1
shift

if test $# -eq 0; then
  check_target_set
  TARGETS=$XYZ_TARGET
else
  TARGETS=$@
fi

TRAP_NOTIFY=1
. setup_atexit

for T in $TARGETS; do
  T=$(get_target $T $TASK)

  DST=$XYZ_INSTALL_ROOT/$XYZ_TASK/$T

  test -d $DST || mkdir -p $DST

  SRC=$XYZ_INSTALL_ROOT/$TASK/$T
  if ! test -d $SRC; then
    echo >&2 "no tools for task $TASK and target $T"
    exit 1
  fi

  rm -rf $DST
  cp -r $SRC $DST

  echo "Copied $T tools from task $TASK on $(date)" | tee $DST/from.txt
done
