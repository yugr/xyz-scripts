#!/bin/sh

# Copyright 2026 Yury Gribov
#▫
# Use of this source code is governed by MIT license that can be
# found in the LICENSE.txt file.

set -eu
shift
source set_paths

OPT=3

usage_short() {
  CMD=$(basename $0 .sh)
  cat >&2 <<EOF
Usage: cv run-lit-tests [OPT]... CFG [-- LIT-OPT...]
For more info run \`cv help $CMD'
EOF
  exit 1
}

usage() {
  cat >&2 <<EOF
Usage: cv run-lit-tests [OPT]... CFG [-- LIT-OPT...]

Available options:
  -h, --help                  Print help and exit.
  -x                          Enable debug mode.
  -n, --ninja                 Run Ninja tests instead of VS.
  -o N, --opt N               Use optimization level (default is $OPT).
EOF
  exit 1
}

ARGS=$(getopt -o 'hnxo:' --long 'ninja,opt:,help' -n $(basename $0) -- "$@")
eval set -- "$ARGS"

NINJA=
while true; do
  case "$1" in
    -o | --opt)
      OPT=$2
      shift 2
      ;;
    -h | --help)
      usage
      ;;
    -x)
      set -x
      shift
      ;;
    -n | --ninja)
      NINJA=1
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

if test $# -lt 1; then
  usage_short
fi

CONFIG=$1
shift

check_llvm_task_set
check_config $CONFIG
check_target_set

TRAP_NOTIFY=1
. setup_atexit

# TODO: make these configurable?
NCPUS=$(ncpus)
LOG="run-lit-tests-$(date +%F-%R).log"

case $XYZ_CORE in
Q4)
  CFG_CORE=xyzq4
  ;;
R2)
  CFG_CORE=xyzr2
  ;;
*)
  echo >&2 "Core $XYZ_CORE is not yet supported"
  exit 1
  ;;
esac
CFG_FILE=lit_default-$CFG_CORE-O$OPT.json

if test $XYZ_ABI = COFF; then
  abi=coff
else
  abi=elf
fi

if test -n "$NINJA"; then
  cd $XYZ_LLVM_BUILD-ninja-$CONFIG/test/lit
else
  cd $XYZ_LLVM_BUILD/test/lit
fi

echo "Running lit tests for task $XYZ_TASK, core $XYZ_CORE. Results will be stored in $LOG"

# Remove Cygwin from PATH to avoid using Cygwin's bash (see TFS #145947)
NEW_PATH=$(filter_cygwin_path)
PATH=$NEW_PATH /usr/bin/nice python run.py -j$NCPUS --build-type $CONFIG --opt-file $CFG_FILE --param BINFMT=$abi "$@" 2>&1 | tee $LOG
