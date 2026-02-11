#!/bin/sh

# This is known to work for XTS v349+
# (except for v352 which has an unhealthy mix of old and new styles).
# Older layouts can be supported as well, if necessary.

set -eu
shift
source set_paths

usage_short() {
  CMD=$(basename $0 | sed 's/\.sh$//')
  cat >&2 <<EOF
Usage: cv download-xts-tools [OPT] BUILD [CORE]...
For more info run \`cv help $CMD'
EOF
  exit 1
}

usage() {
  cat >&2 <<EOF
Usage: cv download-xts-tools [OPT] BUILD [CORE]...

Available options:
  -h, --help    Print help and exit.
  -x            Enable debug mode.

Example:
  $ cv download-xts-tools 348 P4500
  $ cv download-xts-tools LLVM_20180912.5 P4500

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

TMP=$(mktemp -d)

TRAP_CMD="rm -rf $TMP"
TRAP_NOTIFY=1
. setup_atexit

B=$1
shift

if test $# -ge 1; then
  CORES=$@
else
  check_target_set
  CORES=$XYZ_CORE
fi

if echo $B | grep -q '^20[0-9.]\+$'; then
  B="PUSH_$B"
fi

cd $TMP

if echo $B | grep -q '^\(PUSH\|LLVM\)'; then
  DST=$XYZ_INSTALL_ROOT/$B
  mkdir -p $DST

  # Sanity check
  for C in $CORES; do
    TARGET=$C-ELF
    if test -d $DST/$TARGET; then
      echo >&2 "Cowardly refusing to overwrite existing $DST/$TARGET folder"
      exit
    fi
  done

  SUBDIR=
  for C in $CORES; do
    C=$(get_core $C)
    c=$(echo $C | tr 'A-Z' 'a-z')

    TARGET=$C-ELF

    if echo $B | grep -q '^LLVM'; then
      BB=$XYZ_COMPILE_AND_TEST_JOB_ROOT/$B/$c/tools
      if ! test -d $BB; then
        # Try to mimic job name modifications done by XTS
        B_=$(echo $B | tr '.' '_')
        BB=$XYZ_COMPILE_AND_TEST_JOB_ROOT/$B_/$c/tools
      fi
      if ! test -d $BB; then
        echo >&2 "Windows tools for core $C and build $B (or $B_) not found in $BB"
#        exit 1
        continue
      fi
    else
      if test -z "$SUBDIR"; then
        for d in $XYZ_PUSH_JOB_ROOT/*; do
          if test -d "$d/$B/$c/tools"; then
            echo "Using branch $(basename $d)..."
            SUBDIR=$(basename $d)/$B/$c
            break
          elif test -d "$d/$c/$B/tools"; then  # Old path structure
            echo "Using branch $(basename $d)..."
            SUBDIR=$(basename $d)/$B/$c
            break
          fi
        done
      fi
      BB=$XYZ_PUSH_JOB_ROOT/$SUBDIR/tools
      if ! test -d "$BB"; then
        echo >&2 "Windows tools for core $C and build $B not found in $BB"
#        exit 1
        continue
      fi
    fi


    cp -r $BB $DST/$TARGET

    if ls -1 $DST/$TARGET | grep -iq '\.zip'; then
      unzip -q $DST/$TARGET/*.zip -d $DST/$TARGET
      rm -f $DST/$TARGET/*.zip
      chmod +x $DST/$TARGET/xyztools/*/*.exe $DST/$TARGET/xyztools/*/*.dll
    elif test -d $DST/$TARGET/zip/xyztools; then
      mv $DST/$TARGET/zip/xyztools $DST/$TARGET
      rm -rf $DST/$TARGET/zip
    else
      echo >&2 "Unknown layout of $BB, aborting"
      exit 1
    fi

    echo "Copied from $BB on $(date)" > $DST/$TARGET/from.txt
  done
else
  B=$(echo $1 | sed 's/^v//')

  DST=$XYZ_INSTALL_ROOT/v$B
  mkdir -p $DST

  # Sanity check
  for C in $CORES; do
    TARGET=$C-COFF
    if test -d $DST/$TARGET; then
      echo >&2 "Cowardly refusing to overwrite existing $DST/$TARGET folder"
      exit
    fi
  done

  for C in $CORES; do
    C=$(get_core $C)
    TARGET=$C-COFF

    if test $C = P4500; then
      D=P4_Open64
    else
      D=$C
    fi

    B_NUM=$(echo $B | sed 's/^\([0-9]\+\).*/\1/')
    if echo $B | grep -qv '_\.' && test $B_NUM -lt 374; then
      # Ancient times of q:\
      BB=$XYZ_XTS_ROOT_OLD/$D/builds/v$B
    else
      # New shiny y:\
      BB=$XYZ_XTS_ROOT/$D/v$B
    fi

    if ! test -d $BB/tools; then
      echo >&2 "Windows tools for core $C and build $B not found in $BB"
#      exit 1
      continue
    fi

    if uname -n | grep -qi Belfast0; then
      # Herzeliya VMs are fast so just use plain copy
      cp -r $BB/tools $DST/$TARGET
    else
      remote_local_copy $BB/tools
      mv tools $DST/$TARGET
    fi

    if test -f $DST/$TARGET/*.zip; then
      unzip -q $DST/$TARGET/*.zip -d $DST/$TARGET
      rm -f $DST/$TARGET/*.zip
      chmod +x $DST/$TARGET/*/*.exe $DST/$TARGET/*/*.dll
    fi

    echo "Copied from $BB on $(date)" > $DST/$TARGET/from.txt
  done
fi
