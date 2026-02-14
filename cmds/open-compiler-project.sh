#!/bin/sh

set -eu
shift
source set_paths

usage_short() {
  CMD=$(basename $0 .sh)
  cat >&2 <<EOF
Usage: cv open-compiler-project [TASK]
For more info run \`cv help $CMD'
EOF
  exit 1
}

usage() {
  cat >&2 <<EOF
Usage: cv open-compiler-project [TASK]
Open Visual Studio for task TASK (by default opens for currently selected task).

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

if test $# = 1; then
  source cv set-task $1
elif test $# = 0; then
  check_task_set
else
  usage_short
fi

if is_llvm_task $XYZ_TASK; then
#  DEVENV=$MSVS14/devenv
#  DEVENV=$MSVS15/devenv
  DEVENV=$MSVS16/devenv
  PRJ=XYZ_q4_main.sln

  cd $XYZ_LLVM_BUILD
else
  # Ignore installed files
  TRASH=$(cygpath -w $TMP)
  export XYZRTOOLS="$TRASH"
  export XYZPTOOLS="$TRASH"
  export XYZP12TOOLS="$TRASH"
  export Q4TOOLS="$TRASH"
  export XYZQTOOLS="$TRASH"
  export XYZQ6TOOLS="$TRASH"
  export Q6TOOLS="$TRASH"

  DEVENV=$MSVS10/devenv
  PRJ=XYZ_Open64.sln

  cd $XYZ_O64_BUILD
fi

PATH=$(filter_cygwin_path) /usr/bin/cygstart "$(cygpath "$DEVENV")" $PRJ
