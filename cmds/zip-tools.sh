#!/bin/sh

set -eu
shift
source set_paths

usage() {
  cat >&2 <<EOF
Usage: cv zip-tools [CORE]
Create .zip file with tools.

Options:
  -x                     Enable debug mode.
  -h, --help             Print help and exit.
EOF
  exit 1
}

check_task_set

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

TRAP_NOTIFY=1
. setup_atexit

if test -n "${1:-}"; then
  source cv set-target $1
else
  check_target_set
fi
check_tools_in_path

if is_llvm_task $XYZ_TASK; then
  (cd $XYZ_INSTALL/../.. && zip -q -r xyztools.zip xyztools)
  Z=$XYZ_INSTALL/../../xyztools.zip
else
  D=$(get_XYZ_dir $XYZ_TASK $XYZ_CORE)
  (cd $XYZ_INSTALL/.. && zip -q -r $D.zip $D)
  Z=$XYZ_INSTALL/../$D.zip
fi

echo "Created $Z ($(cygpath -w $Z))"
