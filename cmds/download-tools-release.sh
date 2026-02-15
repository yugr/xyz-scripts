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
Usage: cv download-tools-release [OPT] path/to/tools [core]
For more info run \`cv help $CMD'
EOF
  exit 1
}

usage() {
  cat >&2 <<EOF
Usage: cv download-tools-release [OPT] path/to/tools [core]

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
  usage_short
fi

path=$(cygpath "$1")

if test $# -ge 2; then
  core=$(get_core "$2")
else
  core=
fi

wd=$(mktemp -d)
TRAP_CMD="rm -rf $wd"
TRAP_NOTIFY=1
. setup_atexit

get_core_subdir() {
  case $1 in
  P*)
    echo XYZ-P
    ;;
  R2)
    echo XYZ-R
    ;;
  Q*)
    echo XYZ-$core
    ;;
  *)
    echo >&2 "Don't know how to download tools for core $core"
    exit 1
    ;;
  esac
}

if echo "$path" | grep -q Bintools; then
  # Example paths:
  # ...

  last=$(basename "$path")
  if echo $last | grep -q '^XYZ-'; then
    if test -n "$core" -a $last != "$core"; then
      echo >&2 "Core specified in path ($last) does not match the one provided by caller ($core)"
      exit 1
    fi
    core=$last
  else
    if test -z "$core"; then
      echo >&2 "Unable to determine core from path, you need to specify it explicitly"
      exit 1
    fi
  fi

  wd=$path/$(get_core_subdir $core)

  if ! rel=$(echo "$path" | grep -o '\(Bintools\|Bin_Main\)_[^\/]*\.[0-9]\+' | head -1); then
    echo >&2 "Failed to determine release name for $path"
    exit 1
  fi
elif echo "$path" | grep -q Main_Full; then
  # Example paths:
  # ...

  if test -z "$core"; then
    echo >&2 "Need to specify core when downloading debugger"
    exit 1
  fi

  if ! rel=$(echo "$path" | grep -o 'Main_Full_[^\/]*\.[0-9]\+' | head -1); then
    echo >&2 "Failed to determine release name for $path"
    exit 1
  fi

  w32=$(get_the_only_matching_file "$path" Main_Win32)

  COMMON="$path"/$w32/Main_*-Common.zip
  if ! test -f $COMMON; then
    COMMON="$path"/$w32/Main_*-AllCores.zip
  fi
  unzip -q $COMMON -d $wd

  unzip -q "$path"/$w32/Main_*-$(get_core_subdir $core).zip -d $wd

#  MSS="$path"/$w32/Main_*-GenericMss.zip
#  if test -f $MSS; then
#    unzip -q $MSS -d $wd
#  fi
elif echo "$path" | grep -q 'RC.zip$'; then
  # Example paths:
  # ...

  if test -z "$core"; then
    echo >&2 "Need to specify core when downloading debugger"
    exit 1
  fi

  rel=$(basename $(dirname "$path"))
  unzip -q $path -d $wd
else
  echo >&2 "Unknown type of Tools release: $path"
  exit 1
fi

dst=$HOME/Tools-rels/$rel/$(get_core_subdir $core)
if test -d $dst; then
  echo >&2 "Folder for release $rel already exists at $dst, deleting..."
  rm -rf $dst
fi
mkdir -p $dst
cp -r $wd/* $dst
