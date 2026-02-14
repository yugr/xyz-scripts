#!/bin/sh

# This should work for XTS v349+
# Older layouts can be supported as well, if necessary.

set -eu
set -x
shift
source set_paths

usage_short() {
  CMD=$(basename $0 .sh)
  cat >&2 <<EOF
Usage: cv download-xts-results [OPT]... BASE-BUILD [CORE]...
For more info run \`cv help $CMD'
EOF
  exit 1
}

usage() {
  cat >&2 <<EOF
Usage: cv download-xts-results [OPT]... BASE-BUILD [CORE]...

Available options:
  -h, --help    Print help and exit.
  -x            Enable debug mode.

Example:
  $ cv download-xts-results 348 P4500

CORE can be a list of P4500, R2, Q4, Q6 or P12.
If CORE is not specified, results for currently set core are loaded.

Available builds (takes some time to print...):
EOF
  print_builds >&2
  exit
}

ARGS=$(getopt -o 'xh' --long 'help' -n $(basename $0) -- "$@")
eval set -- "$ARGS"
while true; do
  case "$1" in
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

if test $# = 0; then
  usage_short
fi

TRAP_NOTIFY=1
. setup_atexit

B=$(echo $1 | sed 's/^v//')
shift

if test $# -ge 1; then
  CORES=$@
else
  check_target_set
  CORES=$XYZ_CORE
fi

exists() {
  # nullglob
  test $(ls -1d $1* | grep -v '\*' | wc -l) -gt 0
}

LOGS=

for C in $CORES; do
  C=$(get_core $C)
  c=$(echo $C | tr 'A-Z' 'a-z')

  if echo $B | grep -q '^[0-9]\+$' && test $B -lt 353 -a $C = Q6; then
    echo >&2 "Q6 not available in builds prior to 353, skipping..."
    continue
  fi

  # TODO: do we need to support old layout in q:\ ?
  case $C in
  P4500)
    BB=$XYZ_XTS_ROOT/XYZP4_Open64/v$B
    ;;
  R2 | Q4 | Q6)
    BB=$XYZ_XTS_ROOT/$C/v$B
    ;;
  *)
    echo >&2 "Unknown core: $C"
    exit 1
  esac

  # Zoo of different naming conventions...

  if test -d $BB/win_res; then
    # First try new layout (since v353): Q:\Tools\XTS_tests_run\XYZP4_Open64\builds\v353\win_res
    WIN=$BB/win_res
  elif test $C = P4500; then
    # Legacy P4500 layout: Q:\Tools\XTS_tests_run\XYZP4_Open64\builds\v351
    WIN=$BB
  elif test $C = R2; then
    # Legacy R2 layout: Q:\Tools\XTS_tests_run\R2\builds\v351\res_linux
    WIN=$BB/res
  elif test $C = Q4; then
    # Legacy Q4 layout: Q:\Tools\XTS_tests_run\Q4\builds\v351\res
    WIN=$BB/res
  fi

  if ! test -d $WIN; then
    echo >&2 "Windows logs for core $C and build $B not found in $BB"
#    exit 1
  else
    WINS=$(ls -1 $WIN)
    if echo "$WINS" | grep -q v${B}_4500__; then
      # v354_4500__cw667dhmswz
      WIN=$(ls -1d $WIN/v${B}_4500__* || true)
    elif echo "$WINS" | grep -q "v${B}_${C}__"; then
      # v427_59_P12__ay17x1nqwa9
      WIN=$(ls -1d $WIN/v${B}_${C}__*)
    else
      # v352_P4500_FULL__ch5v06c4yk4
      WIN=$(ls -1d $WIN/v${B}_${C}_FULL__* || true)
    fi

    for d in $WIN; do
      if ! test -d $d; then
        echo >&2 "Windows logs for core $C and build $B not found in $BB"
        exit 1
      fi
    done

    LOGS="$LOGS $WIN"
  fi

  if test -d $BB/linux_res; then
    # First try new layout (since v353): Q:\Tools\XTS_tests_run\P4_Open64\builds\v353\linux_res
    LINUX=$BB/linux_res
  elif test $C = P4500; then
    # Legacy P4500 layout: Q:\Tools\XTS_tests_run\P4_Open64\builds\v351\res_lin
    LINUX=$BB/res_lin
    if test -d $BB/res_linux; then
      #  Q:\Tools\XTS_tests_run\R\builds\v351\res\v351_R_FULL__cl7jb94emq2
      LINUX=$BB/res_linux
    else
      # Q:\Tools\XTS_tests_run\R\builds\v349\res\v349_R_FULL_LINUX__bwr8w1ubwmq
      LINUX=$BB/res
    fi
  elif test $C = Q4; then
    # Legacy Q4 layout: Q:\Tools\XTS_tests_run\Q4\builds\v351\res
    LINUX=$BB/res
  else
    LINUX=
  fi

  if ! test -d "$LINUX"; then
    echo >&2 "Linux logs for core $C and build $B not found in $BB"
#    exit 1
  else
    LINS=$(ls -1 $LINUX)
    if echo "$LINS" | grep -q v${B}_${C}_LINUX_FULL__; then
      # v354_R_LINUX_FULL__1di36bo1kkb
      LINUX=$(ls -1d $LINUX/v${B}_${C}_LINUX_FULL__* || true)
    elif echo "$LINS" | grep -q v${B}_${c}_LINUX__; then
      # v348_p4500_LINUX__kpbt4syrh1w
      LINUX=$(ls -1d $LINUX/v${B}_${c}_LINUX__* || true)
    elif echo "$LINS" | grep -q v${B}_${C}_Linux__; then
      # v427_59_P12_Linux__ya1a80hyzsd
      LINUX=$(ls -1d $LINUX/v${B}_${C}_Linux__* || true)
    else
      # New layout: v352_P4500_FULL_LINUX__hcajx9mtqc5
      LINUX=$(ls -1d $LINUX/v${B}_${C}_FULL_LINUX__* || true)
    fi

    for d in $LINUX; do
      if ! test -d $d; then
        echo >&2 "Linux logs for core $C and build $B not found in $BB"
#        exit 1
        continue  # Linux logs are often missing so do not abort
      fi
    done

    LOGS="$LOGS $LINUX"
  fi
done

# TODO: it would be faster to archive and copy all at once
# TODO: get rid of res/ folders
for L in $LOGS; do
  remote_local_copy $L
done

