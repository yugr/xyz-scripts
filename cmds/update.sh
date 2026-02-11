#!/bin/sh

set -eu
shift
source set_paths

check_task_set

usage() {
  cat >&2 <<EOF
Usage: cv update [OPT]... [PRJ]...
Update local code from version control system.

Options:
  -h, --help     Print help and exit.
  -x             Enable debug mode.
  -e             Abort on first warning.
EOF
  exit
}

ARGS=$(getopt -o 'hxe' --long 'help' -n $(basename $0) -- "$@")
eval set -- "$ARGS"

E=
while true; do
  case "$1" in
    -h | --help)
      usage
      ;;
    -x)
      set -x
      shift
      ;;
    -e)
      E=1
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

WARNS=
warn() {
  echo >&2 "!!! warning: $1"
  WARNS="$WARNS $2"
  if ! test -z "$E"; then
    echo >&2 "Aborting"
    exit 1
  fi
}

if is_llvm_task $XYZ_TASK; then
  cd $XYZ_LLVM_SOURCE
  if test $# -gt 0; then
    PRJS="$@"
  else
    PRJS=$(ls -1)
  fi
  for d in $PRJS; do
    test -d $d -a -d $d/.git || continue
    cd $d
    if git symbolic-ref -q --short HEAD; then
      b=$(git symbolic-ref --short HEAD)
      bb=$(git branch -a | grep -v '\/' | grep -q $XYZ_TASK || true)
      if test $b != $XYZ_TASK && test -n "$bb"; then
        warn "new remote branch(es) were added in repo $d; you may want to switch to one of them: $bb" $d
      fi
      echo Synching $(basename $d):$b
      if ! git pull --ff-only; then
        warn "failed to pull $d:$b" $d
      fi
    else
      echo Synching $(basename $d)
      git fetch
    fi
    cd ..
  done
  if test -n "$WARNS"; then
    echo >&2 "!!! Warning(s) reported for project(s): $WARNS"
  fi
else
  if test $# = 0; then
    PRJS=compiler
  else
    PRJS="$@"
  fi
  for d in $PRJS; do
    case "$d" in
      Compiler | compiler)
        (cd $XYZ_O64_SOURCE && tf get /recursive .)
        shift
        ;;
      Libs | libs | Lib | lib)
        (cd $XYZ_O64_LIBS && tf get /recursive .)
        shift
        ;;
    esac
  done
fi
