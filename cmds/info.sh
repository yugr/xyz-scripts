#!/bin/sh

set -eu
shift
source set_paths

check_tfs_tools

usage_short() {
  CMD=$(basename $0 | sed 's/\.sh$//')
  cat >&2 <<EOF
Usage: cv info [TASK]
For more info run \`cv help $CMD'
EOF
  exit 1
}

usage() {
  cat >&2 <<EOF
Usage: cv info [TASK]
Prints info about current task.

Available options:
  -h, --help    Print help and exit.
  -x            Enable debug mode.
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
  check_task_set
elif test $# = 1; then
  source cv set-task $1
else
  usage_short
fi

cat <<EOF
List of available tasks:
$(print_tasks)

EOF

cat <<EOF
Installed tools:
$(print_tools)

EOF

if test -z "${XYZ_TASK:-}"; then
  cat <<EOF
There is no current task. Run \`. cv set-task TASK' to set one.
EOF
  exit 0
fi

XYZ_INSTALL=${XYZ_INSTALL:-not set}
if is_llvm_task $XYZ_TASK; then
  cat <<EOF
Currently working on task '$XYZ_TASK':
  source:  $XYZ_LLVM_SOURCE ($(cygpath -w $XYZ_LLVM_SOURCE))
  install: $XYZ_INSTALL ($(cygpath -w $XYZ_INSTALL))
  wdir:    $XYZ_WDIR ($(cygpath -w $XYZ_WDIR)
  core:    ${XYZ_CORE:-not set}
  ABI:     ${XYZ_ABI:-not set}
  branches:
EOF

  print_llvm_branches pretty | sed 's/^/    /'

  for REPO in $XYZ_LLVM_SOURCE/*; do
    if test -d $REPO/.git; then
      (cd $REPO && echo "Status of $REPO:" && git status)
    fi
  done
else
  cat <<EOF
Currently working on task '$XYZ_TASK':
  source:  $XYZ_O64_SOURCE ($(cygpath -w $XYZ_O64_SOURCE))
  install: $XYZ_INSTALL ($(cygpath -w $XYZ_INSTALL))
  wdir:    $XYZ_WDIR ($(cygpath -w $XYZ_WDIR))
  core:    ${XYZ_CORE:-not set}
  branch:  ${XYZ_BRANCH:-default}
EOF

  if test -d $XYZ_O64_SOURCE; then
    cat <<EOF
  VCS:
    $(cd $XYZ_O64_SOURCE && tf history . /r /noprompt /stopafter:1 /version:W | grep '^[0-9]')
EOF
  fi
fi
