#!/bin/sh

# Copyright 2026 Yury Gribov
#▫
# Use of this source code is governed by MIT license that can be
# found in the LICENSE.txt file.

set -eu
shift
source set_paths

if test $# != 0; then
  cat >&2 <<EOF
Usage: cv init

EOF
fi

if alias | grep -q cv=; then
  echo >&2 "Already initialized..."
else
  echo "alias cv='source cv';"
  echo "$(dirname $0)/install-auto-complete.sh DODODO"
fi

