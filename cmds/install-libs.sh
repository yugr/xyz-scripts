#!/bin/sh

set -eu
shift
source set_paths

usage() {
  cat >&2 <<EOF
Usage: cv install-libs [OPT]...

Options:
  -x                           Enable debug mode.
  -h, --help                   Print help and exit.
EOF
  exit 1
}

ARGS=$(getopt -o 'hx' --long 'dry-run,help' -n $(basename $0) -- "$@")
eval set -- "$ARGS"

DRY=
while true; do
  case "$1" in
    --dry-run)
      DRY=1
      ;;
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

if is_llvm_task $XYZ_TASK; then
  echo >&2 "NYI for LLVM tasks (use \`cv install-compiler')"
  exit 1
fi

if ! test -f build_core.bat; then
  echo >&2 "You are not in libs folder (execute \`cv cd libs'?)"
  exit 1
fi

check_task_set
check_target_set
check_install_exists

case $XYZ_CORE in
R2)
  INSTALL_SUBDIR=xyzr2
  OUTPUT_SUBDIR=xyzr2
  ;;
Q4)
  INSTALL_SUBDIR=q4
  OUTPUT_SUBDIR=qq
  ;;
Q6)
  INSTALL_SUBDIR=xyzq6
  OUTPUT_SUBDIR=XYZQ6
  ;;
P4500)
  INSTALL_SUBDIR=p4500
  OUTPUT_SUBDIR=XYZP4500
  ;;
P12)
  INSTALL_SUBDIR=p12
  OUTPUT_SUBDIR=XYZP12
  ;;
*)
  echo >&2 "Don't know how to install libs for core $XYZ_CORE"
  exit 1
  ;;
esac

LIB_INSTALL_DIR=$XYZ_INSTALL/libs
HDR_INSTALL_DIR=$XYZ_INSTALL/include
OUTPUT_DIR=verified_libs/$OUTPUT_SUBDIR

if ! test -d $HDR_INSTALL_DIR; then
  echo >&2 "Target directory $HDR_INSTALL_DIR ($(cygpath $HDR_INSTALL_DIR)) does not exist"
  exit 1
fi

if ! test -d $LIB_INSTALL_DIR; then
  echo >&2 "Target directory $LIB_INSTALL_DIR ($(cygpath $LIB_INSTALL_DIR)) does not exist"
  exit 1
fi

if ! test -d $OUTPUT_DIR; then
  echo >&2 "Source directory $OUTPUT_DIR ($(cygpath $OUTPUT_DIR)) does not exist"
  exit 1
fi

echo "Compare headers:"
(diff -rq $HDR_INSTALL_DIR $OUTPUT_DIR/include | sed 's/^/  /') || true
if test -z "${DRY:-}"; then
  rm -rf $HDR_INSTALL_DIR/*
  cp -r $OUTPUT_DIR/include/* $HDR_INSTALL_DIR
  echo "Installed headers from $OUTPUT_DIR/include to $HDR_INSTALL_DIR"
fi

echo "Compare object libraries:"
(diff -rq $LIB_INSTALL_DIR $OUTPUT_DIR/libs | sed 's/^/  /') || true
if test -z "${DRY:-}"; then
  rm -rf $LIB_INSTALL_DIR/*
  cp -r $OUTPUT_DIR/libs/* $LIB_INSTALL_DIR
  echo "Installed object libraries from $OUTPUT_DIR/libs to $LIB_INSTALL_DIR"
fi

(echo "Installed new libs:" && tf_latest) >> $XYZ_INSTALL/../versions.txt

