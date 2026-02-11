#!/bin/sh

set -eu
shift
source set_paths

usage_short() {
  CMD=$(basename $0 | sed 's/\.sh$//')
  cat >&2 <<EOF
Usage: cv open-spec [OPT]... [CORE]
For more info run \`cv help $CMD'
EOF
  exit 1
}

usage() {
  cat >&2 <<EOF
Usage: cv open-spec [OPT]... [CORE]
Open compiler spec (default is currently selected CORE).

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

if test $# != 1 -a $# != 0; then
  usage_short
fi

if test $# -eq 1; then
  CORE=$(get_core $1)
else
  check_target_set
  CORE=$XYZ_CORE
fi

DOC_DIR="$XYZ_TOOLS_COMMON/Source/Compiler/doc"

case $CORE in
*)
  DOC="$DOC_DIR/XYZ-Toolbox-${CORE}_Compiler_Reference_Guide.docx"
  ;;
esac

if ! test -f "$DOC"; then
  echo >&2 "File '$DOC' ($(cygpath -w '$DOC')) not found"
  exit 1
fi

cygstart "$DOC"
