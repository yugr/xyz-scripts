#!/bin/sh

set -eu
shift
source set_paths

check_tfs_tools

usage_short() {
  cat >&2 <<EOF
Usage: cv create-task [OPTION]... TASK
Run \`cv create-task -h' for more details.
EOF
  exit 1
}

usage() {
  cat >&2 <<EOF
Usage: cv create-task [OPTION]... TASK

Options:
  --no-tfs                       Do not checkout, just create task.
  -b BRANCH1,BRANCH2,...
  --branch BRANCH1,BRANCH2,...   Checkout branch BRANCH (default is trunk for Open64,
                                 develop for LLVM).
  --llvm                         Create LLVM task instead of Open64.
  -x                             Enable debug mode.
  -h, --help                     Print help and exit.

Example:
  $ cv create-task TS102673-lci P4500
  $ cv create-task -b XYZ-P4000/Main-Open64-V16 Some-debug
  $ cv create-task --llvm -b allthethings Common

Current TFS tasks:
(may take some time...)
EOF
  print_tasks tfs >&2
  exit 1
}

ARGS=$(getopt -o 'b:hx' --long 'branch:,no-tfs,help,llvm' -n $(basename $0) -- "$@")
eval set -- "$ARGS"

# TODO: --only
BRANCHES=
NO_TFS=
LLVM=
while true; do
  case "$1" in
    --no-tfs)
      NO_TFS=1
      shift
      ;;
    -b | --branch)
      BRANCHES="$(echo "$2" | tr ',' ' ') develop master"
      shift 2
      ;;
    --llvm)
      LLVM=1
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

if test $# -lt 1; then
  usage_short
fi

TRAP_NOTIFY=1
. setup_atexit

TASK=$1

IDIR=$XYZ_INSTALL_ROOT/$TASK
rm -rf $IDIR
mkdir -p $IDIR
echo "Created install root dir for task at $IDIR"

WDIR=$XYZ_WDIR_ROOT/$TASK
mkdir -p $WDIR
echo "Created workdir for task at $WDIR"

if test -n "$NO_TFS"; then
  :
elif test -n "$LLVM"; then
  SRC=$XYZ_LLVM_ROOT/$TASK
#  if test -d $SRC; then
#    echo >&2 "error: directory with sources already exists at $SRC"
#    exit 1
#  fi

  mkdir -p $SRC
  cd $SRC

  REPOS=''
  REPOS="$REPOS XPLAY_LLVM llvm clang"
  REPOS="$REPOS compiler-rt libc libcxx libcxxabi libunwind"
  REPOS="$REPOS gcc_tests"
  for REPO in $REPOS; do
    git clone -n $XYZ_GIT_SERVER/$REPO
    GIT="git --git-dir=$REPO/.git"
    REPO_BRANCH=
    for B in $BRANCHES; do
      if $GIT rev-parse -q --verify remotes/origin/$B > /dev/null; then
        REPO_BRANCH=$B
        break
      fi
    done
    if test -z "$REPO_BRANCH"; then
      echo >&2 "No known branches in repo $REPO (tried $BRANCHES)"
      exit 1
    fi
    (cd $REPO && git checkout $REPO_BRANCH)
    $GIT config --global user.name 'John Doe'
    $GIT config --global user.email $USER@XYZ-dsp.com
  done

  TOOLS=$(cygpath -m $XYZ_LLVM_REFTOOLS)

  for NINJA in '' '1'; do
    if test -n "$NINJA"; then
      B=-ninja
      cat > configure-ninja.bat <<EOF
cd %~dp0

set CFG=%1
if "%CFG%" == "" set CFG=RelWithDebInfo
mkdir build-ninja-%CFG%
cd build-ninja-%CFG%

$(cygpath -w $XYZ_HELPERS/configure-ninja-impl.bat) ^
EOF
    else
      B=
      cat > configure.bat <<EOF
cd %~dp0

mkdir build
cd build

$(cygpath -w $XYZ_HELPERS/configure-impl.bat) ^
EOF
    fi

    # TODO: -DCMAKE_VERBOSE_MAKEFILE=ON ?
    cat >> configure$B.bat <<EOF
  -DXYZ_TOOLS_COFF_Q4=$TOOLS/Q4-COFF/XYZ-Q4 ^
  -DXYZ_TOOLS_COFF_R2=$TOOLS/R2-COFF/XYZ-X ^
  -DXYZ_TOOLS_ELF_Q4=$TOOLS/Q4-ELF/xyztools/bin ^
  -DXYZ_TOOLS_ELF_R2=$TOOLS/R2-ELF/xyztools/bin ^
  -DXYZ_TOOLS_ELF_S2=$TOOLS/S2-ELF/xyztools/bin ^
  -DXYZ_TOOLS_ELF_Q6=$TOOLS/Q6-ELF/xyztools/bin ^
  -DLM_LICENSE_FILE=$(cygpath -m $XYZ_INSTALL_ROOT)/licence.dat
EOF

#    PATH=$(filter_cygwin_path) cmd /c configure$B.bat
    cat <<EOF
Cmake command has been stored in build/configure$B.bat.
You may need to update paths to tools.
EOF
  done
else
  SRC=$XYZ_TFS_ROOT/$TASK
  if test -d $SRC; then
    echo >&2 "error: directory with sources already exists at $SRC"
    exit 1
  fi

  if test -z "${BRANCH:-}"; then
    O64_SRC=Source/Main-Open64
  else
    O64_SRC=Archive/$BRANCH
  fi

  # This is likely to timeout, hence the last
  mkdir -p $SRC
  cd $SRC
  tf workspace $XYZ_TFS_SERVER /new $TASK
  sleep 5  # TFS server often fails to synch immediately so wait

  echo "Synching sources..."
  tf get /recursive XYZ_DEV/Compiler/xyzx/$O64_SRC
  tf get /recursive XYZ_DEV/Compiler/libs

  echo "Created TFS workspace for task, mapped to $SRC"
fi

echo "You can switch to task via \`cv set-task $TASK'"
