#!/bin/sh

# Copyright 2026 Yury Gribov
#▫
# Use of this source code is governed by MIT license that can be
# found in the LICENSE.txt file.

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

PATH=$(filter_cygwin_path) /usr/bin/cygstart explorer .
echo "Opened $1"

