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
Usage: cv open-spec [OPT]... VER 1|2|3 [CORE]
For more info run \`cv help $CMD'
EOF
  exit 1
}

usage() {
  cat >&2 <<EOF
Usage: cv open-spec [OPT]... VER 1|2|3 [CORE]

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

if test $# != 2 -a $# != 3; then
  usage_short
fi

if test $# -eq 3; then
  CORE=$(get_core $3)
else
  check_target_set
  CORE=$XYZ_CORE
fi

DOC_DIR=$XYZ_TOOLS_COMMON/../Arch

case $CORE in
P12)
  DOC_DIR=$DOC_DIR/XYZ-P/XYZ-P00/Release
  ;;
Q4)
  DOC_DIR=$DOC_DIR/QQ/Release_for_RnD
  ;;
*)
  echo >&2 "NYI for $CORE core"
  exit 1
  ;;
esac

# Hidden flag for autocompleter
if test $1 = 'list'; then
  ls -1 $DOC_DIR | tr '\n' ' '
  exit 0
fi

case $CORE in
P12)
  if test -d $DOC_DIR/$1/pdf; then
    DOC_DIR=$DOC_DIR/$1/pdf
  else
    DOC_DIR=$DOC_DIR/v$1/pdf
  fi
  ;;
Q4)
  if test -d $DOC_DIR/$1/Spec; then
    DOC_DIR=$DOC_DIR/$1/Spec
  else
    DOC_DIR=$DOC_DIR/V$1/Spec
  fi
  ;;
*)
  echo >&2 "NYI for $CORE core"
  exit 1
  ;;
esac

case $2 in
1)
  NAME='Vol[_\-]I[^I]'
  ;;
2)
  NAME='Vol[_\-]II[^I]'
  ;;
3)
  NAME='Vol[_\-]III'
  ;;
*)
  echo >&2 "Unknown spec number: $2"
  exit 1
  ;;
esac


if test $(ls -1 $DOC_DIR | grep -c $NAME) -ne 1; then
  echo >&2 "Spec not found in $DOC_DIR"
  exit 1
fi

cygstart $DOC_DIR/$(ls -1 $DOC_DIR | grep $NAME)
