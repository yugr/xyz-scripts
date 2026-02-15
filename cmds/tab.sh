#!/bin/sh

# Copyright 2026 Yury Gribov
#▫
# Use of this source code is governed by MIT license that can be
# found in the LICENSE.txt file.

# FIXME: just use newtab?

set -eu
shift

STARTUP=$(mktemp)

echo "rm -f $STARTUP" >> $STARTUP
echo "source $HOME/.bashrc" >> $STARTUP

if test -n "${XYZ_TASK:-}"; then
  echo "cv set-task $XYZ_TASK" >> $STARTUP
fi

if test -n "${XYZ_TARGET:-}"; then
  echo "cv set-target $XYZ_TARGET" >> $STARTUP
fi

echo "cd $PWD" >> $STARTUP

# TODO: set all environment vars?

cygstart mintty bash --init-file $STARTUP
