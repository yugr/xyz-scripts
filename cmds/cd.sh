#!/bin/sh

set -eu
shift
source set_paths

usage_short() {
  CMD=$(basename $0 | sed 's/\.sh$//')
  cat >&2 <<EOF
Usage: cv cd [OPT]... [CORE]...
For more info run \`cv help $CMD'
EOF
  exit 1
}

usage() {
  # TODO: fill remaining names
  cat >&2 <<EOF
Usage: cv cd [OPT]... [CORE]...
Goto to one of predefined directories (or copy to clipboard).

Available options:
  -n, --ninja CFG  Chdir to Ninja directory (with config CFG).
  -c, --clip       Put path to clibboard instead of changing to it.
  -e, --explore    Open Explorer in folder instead of changing to it.
  -f               When using T@, forcedly synchronize target directory.
  -h, --help       Print help and exit.
  -x               Enable debug mode.

Supported dirs:
  T@path/to/test   XTS test located in path/to/test (synched if not exists).
  $/XYZ_DEV/...   TFS location (for current task or Common if none set).
EOF
  print_cd_targets pretty
  exit
}

ARGS=$(getopt -o 'hfxn:ce' --long 'help,force,ninja:,clip,explore' -n $(basename $0) -- "$@")
eval set -- "$ARGS"

FORCE=
NINJA=
EXPLORE=
CLIP=
while true; do
  case "$1" in
    -h | --help)
      usage
      ;;
    -x)
      set -x
      shift
      ;;
    -n)
      NINJA=$(get_config $2)
      shift 2
      ;;
    -f | --force)
      FORCE=$1
      shift
      ;;
    -c | --clip)
      CLIP=1
      shift
      ;;
    -e | --explore)
      EXPLORE=1
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

D=$(echo "$1" | tr '\' /)

if echo "$D" | grep -q '^T@'; then
  T=$(echo "$D" | sed 's/^T@//')
  if echo "$T" | grep -q '^\$[\/\\]XYZ_DEV'; then
    $(dirname $0)/helpers/error "Leading T@ is redundant"
    exit 1
  fi
  DIR=$XYZ_QA_COMPILER/tests/$T
  if test ! -d "$DIR" -o -n "$FORCE"; then
    cv synch $FORCE "$D" >&2
  fi
  # Allow user to specify filename to simplify copy-paste from XTS logs
  # which have e.g. ./regression/test/test instead of test.c.
  if test ! -d "$DIR" -o -n "$FORCE"; then
    D=$(dirname "$D")
    DIR=$(dirname "$DIR")
    cv synch $FORCE "$D" >&2
  fi
elif echo "$D" | grep -q '^\$\/'; then
  T=$(echo "$D" | sed 's/^\$\///')
  if test -z "${XYZ_TASK:-}"; then
    XYZ_TASK=Common
  fi
  DIR=$XYZ_TFS_ROOT/$XYZ_TASK/"$T"
elif DIR=$(NINJA=$NINJA get_sym_dir ${1:=}); then
  :
elif test -d "$D"; then
  DIR=$(cygpath "$D")
else
  cat >&2 <<EOF
error: unknown destination '$D'; supported destinations are
  $(print_cd_targets)"
EOF
  exit 1
fi

if test -z "${DIR:=}"; then
  echo >&2 "Directory '${1:=}' not found"
  exit 1
elif ! test -d "$DIR"; then
  echo >&2 "Directory $DIR ($(cygpath -w $DIR)) does not exist"
  exit 1
fi

if test -n "$CLIP"; then
  echo "$DIR" | tr -d '\r\n' | clip
  echo >&2 "Put $DIR to clipboard"
elif test -n "$EXPLORE"; then
  cygstart "$DIR"
  echo >&2 "Opened $DIR in Explorer"
else
  cat <<EOF
cd '$DIR' ;
echo 'Chdirred to $DIR' ;
EOF
fi
