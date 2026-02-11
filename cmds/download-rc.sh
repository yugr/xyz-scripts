#!/bin/sh

set -eu
shift
source set_paths

usage_short() {
  CMD=$(basename $0 | sed 's/\.sh$//')
  cat >&2 <<EOF
Usage: cv download-rc [OPT] NAME [TARGET]
For more info run \`cv help $CMD'
EOF
  exit 1
}

usage() {
  cat >&2 <<EOF
Usage: cv download-rc [OPT] NAME [TARGET]
Download release candidate named NAME for core TARGET.
Default for TARGET is currently set target.

Available options:
  --no-excel    Do not try to read RC location from Excel, just load from std location.
  -h, --help    Print help and exit.
  -x            Enable debug mode.
EOF
  exit
}

ARGS=$(getopt -o 'hx' --long 'help,no-excel' -n $(basename $0) -- "$@")
eval set -- "$ARGS"

NO_XL=
while true; do
  case "$1" in
    -h | --help)
      usage
      ;;
    -x)
      set -x
      shift
      ;;
    --no-excel)
      NO_XL=1
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

if test $# != 1 -a $# != 2; then
  usage_short
fi

NAME=$1

if test $# -ge 2; then
  source cv set-target $2
else
  check_target_set
fi

if test -n "$NO_XL"; then
  path=//fileserver/tools/PreRelease/RCs/Main/$NAME
else
  path=$(python $(cygpath -m $(dirname $0)/helpers/get_rc_link.py) $NAME $XYZ_TARGET)
fi
path="$path"/$(get_the_only_matching_file $path Win64)

wd=$(mktemp -d)
TRAP_CMD="rm -rf $wd"
TRAP_NOTIFY=1
. setup_atexit

DST=$XYZ_INSTALL_ROOT/$NAME/$XYZ_TARGET
if test -d $DST; then
  echo >&2 "Folder for release $NAME already exists at $DST, deleting..."
  rm -rf $DST
fi
mkdir -p $DST

if test $XYZ_ABI = ELF; then
  files='xyztools/*'
else
  files='XYZ-*/*'
fi
unzip -q -d $wd $(cygpath "$path"/RC.zip) "$files"

if test $XYZ_ABI = ELF; then
  cp -r $wd/xyztools $DST
else
  cp -r $wd/XYZ* $DST
fi
chmod -R a+rwx $DST

echo "Copied RC $NAME from $path on $(date)" | tee $DST/from.txt
