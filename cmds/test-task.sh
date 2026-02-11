#!/bin/sh

set -eu
shift
source set_paths

if test $# -gt 2; then
  echo >&2 "Usage: cv test-task [TITLE]"
  exit 1
fi

check_task_set
check_target_set
check_install_exists

TITLE=${1:-"Testing $XYZ_TASK $XYZ_TARGET"}

cd $XYZ_QA_COMPILER
PATH=$(filter_cygwin_path) /usr/bin/cygstart cmd /c "title $TITLE && setenv.bat && cd tests && cmd"

