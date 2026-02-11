#!/bin/sh

set -eu
set -x
shift
source set_paths

DEFAULT_PRIO=15  # Sic!

usage() {
  cat >&2 <<EOF
Usage: cv run-xts [OPTION]... [JOB_NAME]
Creates and optionally runs XTS job.

Example:
  $ cv run-xts --prio 20 p12_floats

Options:
  -p PRIO, --prio PRIO   Set job prio (default is $PRIO).
  --smoke                Runs smoke testsuite (default).
  --full                 Runs full testsuite.
  -t T, --target T       Use target T (by default active target is used).
  -r, --run              Run job (
  -f, --force            Force overwrite existing files.
  -x                     Enable debug mode.
  -h, --help             Print help and exit.
EOF
  exit 1
}

remote_mkdir() {
  # Cygwin mkdir assigns bad perms.
  cmd /c "md $(cygpath -w $1)" || true
#  chmod a+rw "$1"
  sync
}

check_task_set

ARGS=$(getopt -o 'p:hrfxt:' --long 'force,prio:,help,full,smoke,run,target:' -n $(basename $0) -- "$@")
eval set -- "$ARGS"

FULL=
RUN=
PRIO=$DEFAULT_PRIO
FORCE=
TARGET=

while true; do
  case "$1" in
    -t | --target)
      TARGET=$2
      shift 2
      ;;
    -r | --run)
      RUN=1
      shift
      ;;
    -p | --prio)
      PRIO="$2"
      shift 2
      ;;
    --full)
      FULL=1
      shift
      ;;
    -f | --force)
      FORCE=1
      shift
      ;;
    --smoke)
      FULL=
      shift
      ;;
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

TRAP_NOTIFY=1
. setup_atexit

if test -n "$TARGET"; then
  source cv set-target $TARGET
else
  check_target_set
fi
check_tools_in_path

if test $# = 1; then
  JOB_NAME=$1
elif test $# -gt 1; then
  usage
else
  JOB_NAME=$XYZ_TASK
fi

Y_JOB_DIR=$XYZ_XTS_USERS_ROOT/$USER/$JOB_NAME

JOB_DIR=$XYZ_XTS_XPLAY_ROOT/$USER/$JOB_NAME
MGR='z:\pyxts\runner.py'
# Results should be stored to y:\
remote_mkdir $Y_JOB_DIR  # TODO: remove if XTS creates folder automatically
RES_DIR=$(cygpath -w $Y_JOB_DIR/res)

if test -n "$FULL"; then
  SCOPE_SUFFIX=full
else
  SCOPE_SUFFIX=smoke
fi
BAT=$JOB_DIR/run_${XYZ_CORE}_${XYZ_ABI}_${SCOPE_SUFFIX}.bat

umask 0

remote_mkdir $JOB_DIR

if test -d $JOB_DIR/tools/$XYZ_TARGET -o -f $BAT; then
  if test -z "$FORCE"; then
    echo >&2 "cowardly refusing to overwrite files in $JOB_DIR"
    exit 1
  fi
  rm -rf $JOB_DIR/tools/$XYZ_TARGET $BAT || true
fi

echo "Creating batch files in $JOB_DIR..."

core=$(echo $XYZ_CORE | tr 'A-Z' 'a-z')

rm -f $BAT
# For some reason unix2dos blocks so just using explicit \r.
# Also need to create files using cmd.exe to avoid problems with perms.
# TODO: bail out on error
cmd /c "echo > $(cygpath -w $BAT)"
cat > $BAT <<EOF
cd %~dp0
call python $RUNNER submit ^
  --force ^
EOF

if is_llvm_task $XYZ_TASK; then
  cat >> $BAT <<EOF
  --tree z:\\defaultTS\\tests ^
EOF

  PARAMS='-llvm -llvm_ver=4.0.1 -O[0;3;4;s;z] -Wl,-noAlign -ep'
  if test $XYZ_ABI = COFF; then
    PARAMS="$PARAMS -DCOFF"
    D=$(get_XYZ_dir $XYZ_TASK $XYZ_CORE)
  else
    PARAMS="$PARAMS -elf -Wa,-noRstrCheck"
    D='xyztools\bin'
  fi

  case "$XYZ_CORE" in 
  R2 | R21 | R22 | S1 | S2)
    # TODO: can we get rid of -noRstrCheck for R2?
    cat >> $BAT <<EOF
  z:\\pyxts\\xplay_r2.cfg ^
  tools[TOOLS]=%CD%\\tools\\$XYZ_TARGET ^
  env[XYZRTOOLS]=\${TOOLS}\\$D ^
  params="$PARAMS -Wa,-no-asm-check" ^
EOF
    ;;
  Q4)
    cat >> $BAT <<EOF
  z:\\pyxts\\xplay.cfg ^
  tools[TOOLS]=%CD%\\tools\\$XYZ_TARGET ^
  env[Q4TOOLS]=\${TOOLS}\\$D ^
  params="$PARAMS" ^
EOF
    ;;
  *)
    echo >&2 "Unsupported core $XYZ_CORE"
    exit 1
  esac
#  cat >> $BAT <<EOF
#  remove_res_when_done=no ^
#EOF
else  # COFF case
  case "$XYZ_CORE" in 
  P12)
    LIST=p12_list.txt
    ;;
  P4500)
    LIST=p4500_list.txt
    ;;
  R2 | Q4 | Q6)
    LIST=list.txt
    ;;
  *)
    echo >&2 "Unsupported core $XYZ_CORE"
    exit 1
  esac

  if test -n "$FULL"; then
    cat >> $BAT <<EOF
  --tree y:\\defaultTS\\tests ^
  compiler\\cfgs\\$core.cfg ^
EOF
  else
    cat >> $BAT <<EOF
  --list compiler\\lists\\$LIST ^
  --remove_list compiler\\lists\\long_tests.txt ^
  compiler\\cfgs\\${core}_list.cfg ^
EOF
  fi

  case "$XYZ_CORE" in
  P12)
    cat >> $BAT <<EOF
  tools[XYZPTOOLS]=%CD%\\tools\\$XYZ_TARGET\\XYZ-P12.zip ^
  tools[XYZP12TOOLS]=%CD%\\tools\\$XYZ_TARGET\\XYZ-P12.zip ^
EOF
    ;;
  R2)
    cat >> $BAT <<EOF
  tools[XYZRTOOLS]=%CD%\\tools\\$XYZ_TARGET\\XYZ-R.zip ^
EOF
    ;;
  Q4)
    cat >> $BAT <<EOF
 tools[Q4TOOLS]=%CD%\\tools\\$XYZ_TARGET\\XYZ-Q4.zip ^
EOF
    ;;
  Q6)
    cat >> $BAT <<EOF
 tools[XYZQTOOLS]=%CD%\\tools\\$XYZ_TARGET\\XYZ-Q6.zip ^
EOF
    ;;
  P4500)
    # Y:\XTS_tests_run\Compiler\XYZP4_Open64\v362_12\build_all_run.bat
    cat >> $BAT <<EOF
  tools[XYZPTOOLS]=%CD%\\tools\\$XYZ_TARGET\\XYZ-P.zip ^
EOF
    ;;
  *)
    error "unknown core: $XYZ_CORE"
    ;;
  esac
fi

cat >> $BAT <<EOF
  name=%~n0 ^
  priority=$PRIO ^
  timeout=600
  resultdir=$RES_DIR

pause
EOF

echo "Copy tools..."
remote_mkdir $JOB_DIR/tools/$XYZ_TARGET
if is_llvm_task $XYZ_TASK; then
  (cd $XYZ_INSTALL/../.. && zip -q -r xyztools.zip xyztools)
  mv $XYZ_INSTALL/../../xyztools.zip $JOB_DIR/tools/$XYZ_TARGET
  cp $XYZ_INSTALL/../../*.txt $JOB_DIR/tools/$XYZ_TARGET
else
  # Standard XTS wants zipped tools
  D=$(get_XYZ_dir $XYZ_TASK $XYZ_CORE)
  (cd $XYZ_INSTALL/.. && zip -q -r $D.zip $D)
  mv $XYZ_INSTALL/../$D.zip $JOB_DIR/tools/$XYZ_TARGET
  cp $XYZ_INSTALL/../*.txt $JOB_DIR/tools/$XYZ_TARGET
fi

if test -n "$RUN"; then
  cd $(dirname $BAT)
  cygstart cmd /c $(basename $BAT)
else
  echo "You can now execute $(cygpath -w $BAT)"
fi
