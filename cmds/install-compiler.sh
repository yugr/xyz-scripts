#!/bin/sh

set -eu
shift
source set_paths

usage_short() {
  CMD=$(basename $0 | sed 's/\.sh$//')
  cat >&2 <<EOF
Usage: cv install-compiler [OPT]... CONFIG [TARGET]
For more info run \`cv help $CMD'
EOF
  exit 1
}

usage() {
  # TODO: fill remaining names
  cat >&2 <<EOF
Usage: cv install-compiler [OPT]... CONFIG [TARGET]
Installs compiler to current task's tools directory.

Available options:
  -h, --help          Print help and exit.
  -x                  Enable debug mode.
  -n, --ninja         Install Ninja, rather than VS build.
  -t T, --target T    Use target T (by default active target is used).
EOF
  exit
}

ARGS=$(getopt -o 'hxn' --long 'help,ninja' -n $(basename $0) -- "$@")
eval set -- "$ARGS"

NINJA=
while true; do
  case "$1" in
    -h | --help)
      usage
      ;;
    -x)
      set -x
      shift
      ;;
    -n | --ninja)
      NINJA=1
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

if test $# != 1 -a $# != 2; then
  cat >&2 <<EOF
Usage: cv install-compiler [OPT] CONFIG [TARGET]
Run \`cv install-compiler -h' for more details.
EOF
  exit 1
fi

CONFIG=$(get_config $1)

check_task_set

if test $# -gt 1; then
  source cv set-target $2
else
  check_target_set
fi

if ! test -f $XYZ_INSTALL/dcli.exe; then
  echo >&2 "Install directory $XYZ_INSTALL ($(cygpath -w $XYZ_INSTALL)) is empty!!!"
fi

CORE=$(echo $XYZ_CORE | sed 's/Q4/QQ/')

if is_llvm_task $XYZ_TASK; then
  if test -n "${NINJA:-}"; then
    BUILD=$XYZ_LLVM_BUILD-ninja-$CONFIG/src/llvm
  else
    BUILD=$XYZ_LLVM_BUILD/src/llvm/$CONFIG
  fi
  if ! test -d $BUILD; then
    echo >&2 "Build directory $BUILD ($(cygpath -w $BUILD)) does not exist"
    exit 1
  fi

  mkdir -p $XYZ_INSTALL
  cp $BUILD/bin/clang.exe $BUILD/bin/clang++.exe $XYZ_INSTALL
  if test -f $BUILD/bin/lld.exe; then
    cp $BUILD/bin/lld.exe $XYZ_INSTALL/XYZ-elf-lld.exe
  fi

  V=4.0.1
  if ! test -d $BUILD/lib/clang/$V; then
    V=7.1.0
  fi
  if ! test -d $BUILD/lib/clang/$V; then
    echo >&2 "Failed to find folder $BUILD/lib/clang/$V"
    exit 1
  fi
  
  mkdir -p $XYZ_INSTALL/../lib/clang/$V
  for d in $(get_llvm_triple) include; do
    d=$BUILD/lib/clang/$V/$d
    if ! test -d $d; then
      echo >&2 "warning: directory $d does not exist and will not be installed"
      continue
    fi
    cp -r $d $XYZ_INSTALL/../lib/clang/$V
  done

  (echo "Installed new compiler on $(date):" && print_llvm_branches) >> $XYZ_INSTALL/../../versions.txt

  echo "Installed $CONFIG tools from $BUILD to $XYZ_INSTALL"
else
  if ! test -d $XYZ_O64_BUILD; then
    echo >&2 "Build directory $XYZ_O64_BUILD ($(cygpath -w $XYZ_O64_BUILD)) does not exist"
    exit 1
  fi

  cd $XYZ_O64_BUILD

  CP=../extra/scripts/copy_all_to_tools.bat
  if ! test -f $CP; then
    CP=$XYZ_TOOLS_COMMON/Compiler/xyzx/Source/scripts/copy_all_to_tools.bat
  fi

  export COPY_TO_TOOLS=1  # For older sources
  cmd /c $(cygpath -w $CP) ${CONFIG}_${CORE} $(cygpath -w $XYZ_INSTALL) >&2
  cp be_exe/*_map.txt $XYZ_INSTALL

  (echo "Installed new compiler on $(date):" && cd $XYZ_O64_SOURCE && tf_latest) >> $XYZ_INSTALL/../versions.txt

  echo "Installed $CONFIG tools from $XYZ_O64_BUILD to $XYZ_INSTALL"
fi
