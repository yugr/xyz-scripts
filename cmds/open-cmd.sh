#!/bin/sh

set -eu
shift
source set_paths

if test -n "${1:-}"; then
  if test -d $1; then
    cd $1
  else
    . cv cd $1
  fi
fi

echo $PATH
PATH=$(filter_cygwin_path) /usr/bin/cygstart cmd

