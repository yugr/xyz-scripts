#!/bin/sh

set -eu
shift
source set_paths

usage_short() {
  CMD=$(basename $0 .sh)
  cat >&2 <<EOF
Usage: cv set-target [OPT]... TARGET
For more info run \`cv help $CMD'
EOF
  exit 1
}

usage() {
  cat >&2 <<EOF
Usage: cv set-target [OPT]... TARGET
TARGET is CORE or CORE-ABI.

Options:
  -h, --help   Print help and exit.
  -x           Enable debug mode.
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

if test $# != 1; then
  usage_short
fi

XYZ_CORE=$(get_core ${1%-*})
XYZ_ABI=$(get_abi $1)
if test -z "$XYZ_ABI"; then
  if test -n "${XYZ_TASK:-}"; then
    # Try to determine ABI based on the current task
    if is_llvm_task $XYZ_TASK; then
      XYZ_ABI=ELF
    else
      XYZ_ABI=COFF
    fi
  else
    echo >&2 "Failed to determine ABI for target: $1 (no task set)"
    exit 1
  fi
fi

XYZ_TARGET="$XYZ_CORE-$XYZ_ABI"

# TODO: update UPSTREAM_BUILDS for LLVM
case $XYZ_CORE in
P4000)
  UPSTREAM_BUILDS=$XYZ_XTS_ROOT/XYZP4_Open64/builds
  core=xyzp4210
  ;;
P4500)
  UPSTREAM_BUILDS=$XYZ_XTS_ROOT/XYZP4_Open64/builds
  core=xyzp4500
  ;;
P12)
  UPSTREAM_BUILDS=$XYZ_XTS_ROOT/P12
  core=xyzp12
  ;;
R1 | R2)
  UPSTREAM_BUILDS=$XYZ_XTS_ROOT/R2
  core=xyzr2
  ;;
R21)
  UPSTREAM_BUILDS=$XYZ_XTS_ROOT/R21
  core=xyzr21
  ;;
R22)
  UPSTREAM_BUILDS=$XYZ_XTS_ROOT/R22
  core=xyzr22
  ;;
S1)
  UPSTREAM_BUILDS=$XYZ_XTS_ROOT/S1
  core=xyzs1
  ;;
S2)
  UPSTREAM_BUILDS=$XYZ_XTS_ROOT/S2
  core=xyzs2
  ;;
Q4)
  UPSTREAM_BUILDS=$XYZ_XTS_ROOT/Q4/builds
  core=q4
  ;;
Q6)
  UPSTREAM_BUILDS=$XYZ_XTS_ROOT/Q/builds
  core=q6
  ;;
*)
  cat >&2 <<EOF
error: unknown core: $XYZ_CORE

Supported cores: P4000 (P4210), P4500, P12, R2, S2 (R22), Q4 (QQ), Q6
EOF
  exit 1
esac

case $XYZ_ABI in
COFF | ELF)
  ;;
*)
  cat >&2 <<EOF
error: unknown ABI: $XYZ_ABI

Supported ABIs: COFF ELF
EOF
  ;;
esac

source $(dirname $0)/helpers/unset_task_core_vars

cat <<EOF
export XYZ_TARGET=$XYZ_TARGET
export core=$core
export XYZ_TARGET=$XYZ_TARGET ;
export XYZ_CORE=$XYZ_CORE ;
export XYZ_ABI=$XYZ_ABI ;
echo "Prepared partial environment for target $XYZ_TARGET" ;
EOF

if test -n "${XYZ_TASK:-}"; then
  source $(dirname $0)/helpers/set_task_core_vars
else
  print_shell_ps " $XYZ_TARGET "
fi
