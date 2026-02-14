#!/bin/sh

set -eu
shift
source set_paths

check_tfs_tools

usage_short() {
  CMD=$(basename $0 .sh)
  cat >&2 <<EOF
Usage: cv remove-task [OPT]... [TASK]...
For more info run \`cv help $CMD'
EOF
  exit 1
}

usage() {
  cat >&2 <<EOF
Usage: cv remove-task [OPT]... [TASK]...
Remove tasks.

Options:
  -h, --help     Print help and exit.
  -x             Enable debug mode.

Example:
  $ cv remove-task task289547-loops

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

if test $# = 0; then
  usage_short
fi

for TASK in $@; do
  echo "Removing $TASK..."

  if test -d $XYZ_INSTALL_ROOT/$TASK; then
    rm -rf $XYZ_INSTALL_ROOT/$TASK
    echo "Install folder removed."
  else
    cat >&2 <<EOF
warning: task $TASK not found in $XYZ_INSTALL_ROOT"
EOF
  fi

  if test -d $XYZ_WDIR_ROOT/$TASK; then
    mv $XYZ_WDIR_ROOT/$TASK $XYZ_WDIR_ROOT/Archive
    echo "Task workdir has been moved to $XYZ_WDIR_ROOT/Archive."
  else
    cat >&2 <<EOF
warning: task $TASK not found in $XYZ_WDIR_ROOT"
EOF
  fi

  if is_llvm_task $TASK; then
    if test -d $XYZ_LLVM_ROOT/$TASK; then
      echo "You can issue \`rm -rf $XYZ_LLVM_ROOT/$TASK' to remove source code."
    fi
  else
    if tf workspace /delete $TASK $XYZ_TFS_SERVER; then
      echo "TFS workspace has been removed. You can now issue \`rm -rf $XYZ_TFS_ROOT/$TASK' to remove source code."
    else
      echo >&2 "Failed to remove TFS workspace $TASK"
    fi
  fi
done

