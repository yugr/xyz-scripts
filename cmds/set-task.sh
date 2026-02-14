#!/bin/sh

set -eu
shift
source set_paths

usage_short() {
  CMD=$(basename $0 .sh)
  cat >&2 <<EOF
Usage: cv set-task [OPT]... TASK [CORE]
For more info run \`cv help $CMD'
EOF
  exit 1
}

usage() {
  cat >&2 <<EOF
Usage: cv set-task [OPT]... TASK [CORE]

Options:
  -h, --help     Print help and exit.
  -x             Enable debug mode.

The list of current tasks:
`print_tasks`
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

if test $# != 1 -a $# != 2; then
  usage_short
fi

TASK=$1

XYZ_SOURCE=$XYZ_TFS_ROOT/$TASK/XYZ_DEV/Tools/Compiler
XYZ_O64_SOURCE=$XYZ_SOURCE/xyzx/Source/Main-Open64
XYZ_LLVM_SOURCE=$XYZ_LLVM_ROOT/$TASK

if ! test -d "$XYZ_O64_SOURCE" -o -d "$XYZ_LLVM_SOURCE"; then
  echo >&2 "warning: TFS/LLVM sources for $TASK missing at $XYZ_O64_SOURCE; are you sure the task has been created properly?"
fi

print_shell_ps "$TASK "

NEW_PATH=$(remove_tools_from_path)

# Export for set-target below
export XYZ_TASK=$TASK
export XYZ_SOURCE=$XYZ_SOURCE
export XYZ_WDIR=$XYZ_WDIR_ROOT/$TASK
export XYZ_O64_SOURCE=$XYZ_O64_SOURCE
export XYZ_O64_LIBS=$XYZ_SOURCE/libs
export XYZ_O64_BUILD=$XYZ_O64_SOURCE/XYZ/projects
export XYZ_LLVM_SOURCE=$XYZ_LLVM_SOURCE
export XYZ_LLVM_BUILD=$XYZ_LLVM_SOURCE/build
export PATH="$NEW_PATH"
unset XYZ_INSTALL
unset XYZPTOOLS XYZP12TOOLS XYZRTOOLS Q4TOOLS XYZQTOOLS XYZQ6TOOLS Q6TOOLS

source $(dirname $0)/helpers/unset_task_core_vars

cat <<EOF
export XYZ_TASK=$XYZ_TASK ;
export XYZ_SOURCE=$XYZ_SOURCE ;
export XYZ_O64_SOURCE=$XYZ_O64_SOURCE ;
export XYZ_O64_LIBS=$XYZ_O64_LIBS
export XYZ_O64_BUILD=$XYZ_O64_BUILD ;
export XYZ_LLVM_SOURCE=$XYZ_LLVM_SOURCE
export XYZ_LLVM_BUILD=$XYZ_LLVM_SOURCE/build
export XYZ_WDIR=$XYZ_WDIR ;
export PATH="$PATH" ;
echo >&2 "Prepared environment for task $TASK" ;
EOF

if ! test -d $XYZ_O64_SOURCE && test $(print_branches | wc -l) = 1; then
  B=$(print_branches)
  source $(dirname $0)/set-branch.sh _ $B
fi

if test $# -gt 1; then
  shift
  source $(dirname $0)/set-target.sh _ "$@"
elif test -n "${XYZ_TARGET:-}"; then
  source $(dirname $0)/helpers/set_task_core_vars
fi
