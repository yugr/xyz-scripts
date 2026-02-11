#!/bin/sh

set -eu
shift
source set_paths

check_task_set

if is_llvm_task $XYZ_TASK; then
  echo >&2 "NYI for LLVM tasks (use \`cv build-compiler')"
  exit 1
fi

if ! test -f build_core.bat; then
  echo >&2 "You are not in libs folder (execute \`cv cd libs'?)"
  exit 1
fi

echo "Building libs in '$PWD'..."

check_target_set

case $XYZ_CORE in
R2)
  BAT=build_xyzx.bat
  LOG=xyzr.txt
  ;;
Q4)
  BAT=build_q4.bat
  LOG=a4.txt
  ;;
Q6)
  BAT=build_q6.bat
  LOG=xyzq6.txt
  ;;
P4000)
  BAT='build_core.bat xyzp4210'
  LOG=xyzp4210.txt
  ;;
P4500)
  BAT='build_core.bat xyzp4500'
  LOG=xyzp4500.txt
  ;;
P12)
  BAT='build_p12.bat'
  LOG=xyzp12.txt
  ;;
P5)
  BAT='build_core.bat xyzp5 -no_fork'
  LOG=xyzp5.txt
  ;;
*)
  echo >&2 "Unknown core: $XYZ_CORE"
  ;;
esac

TRAP_NOTIFY=1
. setup_atexit

CPU=$(ncpus)

PATH="$(filter_cygwin_path)" /usr/bin/nice cmd /c "$BAT fork_num=$CPU $@" || true &

sleep 5

#tail -f $LOG | grep '[^0] error\|[^0] warning\|error.*:\|ERROR\|Error\|FAILED\|No such file\|WARNING\|warning.*:' &
tail -f $LOG | grep '[^0] error\|error.*:\|ERROR\|Error\|FAILED\|No such file' &

TRAP_CMD="kill $(jobs -p %2) || true"
. setup_atexit

wait %1
