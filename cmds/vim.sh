#!/bin/sh

# Copyright 2026 Yury Gribov
#▫
# Use of this source code is governed by MIT license that can be
# found in the LICENSE.txt file.

set -eu
shift
source set_paths

usage_short() {
  CMD=$(basename $0 .sh)
  cat >&2 <<EOF
Usage: cv vim [OPT]... FILE [CORE]...
For more info run \`cv help $CMD'
EOF
  exit 1
}

usage() {
  # TODO: fill remaining names
  cat >&2 <<EOF
Usage: cv vim [OPT]... FILE [CORE]...
Open FILE in editor.

Available options:
  -n, --ninja CFG  Chdir to Ninja directory (with config CFG).
  -c, --clip       Put path to clibboard instead of changing to it.
  -h, --help       Print help and exit.
  -i, --install    Open file from tools folder (rather than source code),
                   if applicable.
  -x               Enable debug mode.

Supported FILEs:
  $/XYZ_DEV/...   TFS location (for current task or Common if none set).
EOF
  print_cd_targets pretty
  exit
}

ARGS=$(getopt -o 'hxn:ci' --long 'help,ninja:,clip,install' -n $(basename $0) -- "$@")
eval set -- "$ARGS"

NINJA=
CLIP=
INSTALL=
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
    -c | --clip)
      CLIP=1
      shift
      ;;
    -i | --install)
      INSTALL=1
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

if test $# = 2; then
  F=$1
  source cv set-core $2
elif test $# = 1; then
  F=$1
else
  usage_short
fi

# TODO: T@...
if echo "$F" | grep -q '^\$\/'; then
  T=$(echo "$F" | sed 's/^\$\///')
  if test -z "${XYZ_TASK:-}"; then
    XYZ_TASK=Common
  fi
  FILE=$XYZ_TFS_ROOT/$XYZ_TASK/"$T"
elif FILE=$(NINJA=$NINJA INSTALL=$INSTALL get_sym_file ${F:=}); then
  :
elif test -f "$F"; then
  FILE=$(cygpath "$F")
else
  cat >&2 <<EOF
error: unknown destination '$F'; supported destinations are
  $(print_vim_targets)"
EOF
  exit 1
fi

if test -z "${FILE:=}"; then
  echo >&2 "File '${1:=}' not found"
  exit 1
elif ! test -f "$FILE"; then
  echo >&2 "File $FILE ($(cygpath -w $FILE)) does not exist"
  exit 1
fi

if test -n "$CLIP"; then
  echo "$FILE" | tr -d '\r\n' | clip
  echo >&2 "Put $FILE to clipboard"
else
  exec vim $FILE
fi
