#!/bin/sh

set -eu
shift
source set_paths

usage_short() {
  CMD=$(basename $0 .sh)
  cat >&2 <<EOF
Usage: cv set-branch [OPT]... [BRANCH | -]
For more info run \`cv help $CMD'
EOF
  exit 1
}

usage() {
  cat >&2 <<EOF
Usage: cv set-branch [OPT]... [BRANCH | -]

Options:
  -h, --help     Print help and exit.
  -x             Enable debug mode.

Available branches:
$(print_branches | sed 's/^/  /')
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

BRANCH=$1

check_task_set

if is_llvm_task $XYZ_TASK; then
  echo >&2 "NYI for LLVM"
  exit 1
fi

if test $BRANCH = -; then
  XYZ_O64_SOURCE=$XYZ_TFS_ROOT/$XYZ_TASK/XYZ_DEV/Tools/Compiler/xyzx/Source/Main-Open64
  echo 'unset XYZ_BRANCH; '
else
  XYZ_O64_SOURCE=$XYZ_TFS_ROOT/$XYZ_TASK/XYZ_DEV/Tools/Compiler/xyzx/Archive/$BRANCH

  if ! test -d $XYZ_O64_SOURCE; then
    echo >&2 "Directory for branch not found at $XYZ_O64_SOURCE"
    exit 1
  fi

  echo "export XYZ_BRANCH=$BRANCH ;"
fi

cat <<EOF
export XYZ_O64_SOURCE=$XYZ_O64_SOURCE ;
export XYZ_O64_BUILD=$XYZ_O64_SOURCE/XYZ/projects ;
echo >&2 "Prepared environment for branch $BRANCH" ;
EOF
