#!/bin/sh

set -eu
shift
source set_paths

usage_short() {
  cat >&2 <<EOF
Usage: cv unset-task [OPT]...
Run \`cv unset-task -h' for more details.
EOF
  exit 1
}

usage() {
  cat >&2 <<EOF
Usage: cv unset-task [OPT]...
Reset active task settings.

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

if test $# != 0; then
  usage_short
fi

print_shell_ps ''

NEW_PATH=$(remove_tools_from_path)

cat <<EOF
unset XYZ_TASK ;
unset XYZ_SOURCE ;
unset XYZ_O64_SOURCE ;
unset XYZ_O64_BUILD ;
unset XYZ_LLVM_SOURCE ;
unset XYZ_LLVM_BUILD ;
unset XYZ_WDIR ;
unset XYZ_LIBS ;
unset XYZTOOLBOX ;

export PATH="$NEW_PATH" ;

unset XYZ_INSTALL ;
unset XYZ_TARGET ;
unset XYZ_CORE core ;
unset XYZ_ABI ;
unset XYZPTOOLS XYZP12TOOLS XYZRTOOLS Q4TOOLS XYZQTOOLS XYZQ6TOOLS Q6TOOLS ;
EOF
