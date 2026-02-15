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
Usage: cv open-isdb [OPT]... [CORE]
For more info run \`cv help $CMD'
EOF
  exit 1
}

usage() {
  cat >&2 <<EOF
Usage: cv open-isdb [OPT]... [CORE]
Open ISDB for core CORE (default is currently selected CORE).

Options:
  -h, --help     Print help and exit.
  -x             Enable debug mode.
EOF
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

check_task_set

if test $# = 1; then
  CORE=$(get_core $1)
elif test $# = 0; then
  check_target_set
  CORE=$XYZ_CORE
else
  usage_short
fi

if is_llvm_task $XYZ_TASK; then
  ISDB_DIR=$XYZ_LLVM_SOURCE/llvm/lib/Target/MYTARGET/ISDB
  case $CORE in
  S1 | S2)
    ISDB=$ISDB_DIR/ISDB_S.xlsx
    ;;
  *)
    ISDB=$ISDB_DIR/ISDB_$CORE.xls
    ;;
  esac
else
  ISDB_DIR=$XYZ_O64_SOURCE/XYZ/src/common

  case $CORE in
  P4*)
    ISDB=$ISDB_DIR/XYZ$CORE/ISDB.xls
    ;;
  *)
    ISDB=$ISDB_DIR/$CORE/${CORE}_ISDB.xls
    if ! test -f $ISDB; then
      ISDB=$ISDB_DIR/$CORE/ISDB_${CORE}.xls
    fi
    ;;
  esac
fi

ISDB_XLSX=$(echo $ISDB | sed 's/\.xls$/.xlsx/')
if ! test -f $ISDB; then
  if test -f $ISDB_XLSX; then
    # Some local branches change extension to xlsx
    ISDB=$ISDB_XLSX
  else
    echo >&2 "ISDB not found in $ISDB"
    exit 1
  fi
fi

cygstart $ISDB
