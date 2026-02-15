#!/bin/sh

# Copyright 2026 Yury Gribov
#▫
# Use of this source code is governed by MIT license that can be
# found in the LICENSE.txt file.

set -eu
shift
source set_paths

check_task_set
check_target_set

if is_llvm_task $XYZ_TASK; then
  echo >&2 "Don't know how to open LLVM toolbox"
  exit 1
else
  if ! test -d $XYZTOOLBOX/toolbox; then
    echo >&2 "XYZ Toolbox isn't available in $XYZTOOLBOX"
    exit 1
  fi
  PATH=$(filter_cygwin_path) /usr/bin/cygstart "$XYZTOOLBOX/toolbox/toolbox.exe"
fi
