#!/bin/sh

set -eu
shift
source set_paths

check_tfs_tools

print_shelves() {
  tf shelvesets $XYZ_TFS_SERVER
}

if test $# != 2; then
  cat >&2 <<EOF
Usage: cv autobuild BASE-CHANGESET SHELVESET

Example:
  $ cv autobuild 123456 'Enable feature A v. 1'

EOF

  print_shelves >&2
  exit 1
fi

TRAP_NOTIFY=1
. setup_atexit

CHSET=$1
SHELVE=$2

URL=$(echo $XYZ_TFS_SERVER | sed 's!^/collection:!!')
PRJ=XYZ_DEV

build() {
  "$MSVS10/TFSBuild" start $URL $PRJ $1 /requestedFor:$USER /getOption:Custom /customGetVersion:C$CHSET /shelveset:"$SHELVE"
}

build COMPILER_OPEN64_MAIN &
build COMPILER_OPEN64_LINUX &
wait %1 %2

