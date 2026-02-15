#!/bin/sh

# Copyright 2026 Yury Gribov
#▫
# Use of this source code is governed by MIT license that can be
# found in the LICENSE.txt file.

set -eu
shift
source set_paths

check_tfs_tools

usage_short() {
  cat >&2 <<EOF
Usage: cv diff-tasks [OPTION]... [TASK1] TASK2
Run \`cv diff-tasks -h' for more details.
EOF
  exit 1
}

usage() {
  cat >&2 <<EOF
Usage: cv diff-tasks [OPTION]... [TASK1] TASK2
Compares source code and tools in two tasks.

When TASK1 is not specified current task is assumed.

Options:
  -x                           Enable debug mode.
  -h, --help                   Print help and exit.
EOF
  exit 1
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

if test $# -eq 1; then
  check_task_set
  L=$XYZ_TASK
  R=$1
elif test $# -eq 2; then
  L=$1
  R=$2
else
  usage_short
fi

cdgit() {
  local root=$1
  shift
  (cd $root && git "$@")
}

top() {
  cdgit $1 log --oneline -n1 | awk '{print $1}'
}

branch() {
  cdgit $1 branch | grep '\*' | cut -d ' ' -f2
}

if is_llvm_task $L && ! is_llvm_task $R || ! is_llvm_task $L && is_llvm_task $R; then
  echo 'Tasks are uncomparable (LLVM vs Open64)'
  exit 1
elif is_llvm_task $L; then
  # Compare sources
  if ! test -d $XYZ_LLVM_ROOT/$L/llvm -a -d $XYZ_LLVM_ROOT/$R/llvm; then
    echo 'Unable to compare sources as one of the tasks is missing them'
  else
    for l in $XYZ_LLVM_ROOT/$L/*; do
      b=$(basename $l)
      r=$XYZ_LLVM_ROOT/$R/$b
      if test -d $l -a -d $l/.git; then
        lc=$(top $l)
        rc=$(top $r)
        if test $lc != $rc; then
          echo "Different heads in repo $b: $lc ($(branch $l)) vs $rc ($(branch $r))"
        fi
        # TODO: compare branches
      fi
    done
  fi

  # Compare configures
  diff -q $XYZ_LLVM_ROOT/$L/configure.bat $XYZ_LLVM_ROOT/$R/configure.bat || true
  diff -q $XYZ_LLVM_ROOT/$L/configure-ninja.bat $XYZ_LLVM_ROOT/$R/configure-ninja.bat || true

  # Tools only in left
  left_only=
  for l in $XYZ_INSTALL_ROOT/$L/*; do
    b=$(basename $l)
    r=$XYZ_INSTALL_ROOT/$R/$b
    if test -d $l -a ! -d $r; then
      left_only="$left_only $b"
    fi
  done
  if test -n "$left_only"; then
    echo "Tools only in $L: $left_only"
  fi

  # Tools only in right
  right_only=
  for r in $XYZ_INSTALL_ROOT/$R/*; do
    b=$(basename $r)
    l=$XYZ_INSTALL_ROOT/$L/$b
    if test -d $r -a ! -d $l; then
      right_only="$right_only $b"
    fi
  done
  if test -n "$right_only"; then
    echo "Tools only in $R: $right_only"
  fi

  # Different tools
  for l in $XYZ_INSTALL_ROOT/$L/*; do
    r="$XYZ_INSTALL_ROOT/$R/$(basename $l)"
    if test -d $l -a -d $r; then
      diff -rq $l $r || true
    fi
  done
else
  echo 'Open64 tasks are NYI'
fi
