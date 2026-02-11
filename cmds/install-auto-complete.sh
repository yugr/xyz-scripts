#!/bin/bash

if test "$1" = DODODO; then
  _XYZAutoComplete () {
    local helpers=$(dirname $BASH_SOURCE)/helpers
    local path=$helpers:$PATH

    local targets="r2"
    targets="$targets r22 rv22 r2v2 rv2 s s2"
    targets="$targets q4 qq"
    targets="$targets q6"
    targets="$targets p5"
    targets="$targets p4000 4000"
    targets="$targets p4210 4210"
    targets="$targets p4500 4500"
    targets="$targets p4600 4600 12 p12"
    targets=$(echo "$targets" | sed 's/\([^ ]\+\)/\1 XYZ\1/')  # Allow optional "XYZ" prefix
    targets="$targets $(echo "$targets" | tr 'a-z' 'A-Z')"  # Allow both cases
    targets=$(echo "$targets" | sed 's/\([^ ]\+\)/\1 \1-COFF \1-ELF/')  # Allow optional ABI suffix

    local abis='coff COFF elf ELF'
    local opts='0 3 4 s3 s4 s z'
    local configs=$(PATH=$path get_config)

    local build_compiler_matches
    build_compiler_matches() {
      if test $1 = POSITIONAL -a $2 = 0; then
        echo "$configs"
      elif test $1 = FLAG; then
        echo '-h --help -n --ninja -o --only'
      fi
    }

    local copy_tools_matches
    copy_tools_matches() {
      if test $COMP_CWORD = 2; then
        PATH=$path print_tools short
      elif test $COMP_CWORD = 3; then
        echo "$targets"
      fi
    }

    local create_task_matches
    create_task_matches() {
      if test $1 = POSITIONAL -a $2 = 0; then
        cat >&2 <<EOF

(autocompletion may take some time...)
EOF
        PATH=$path print_tasks tfs | tr '\n' ' '
      elif test $1 = FLAG; then
        echo '-h --help -b --branch --llvm --no-tfs'
      fi
    }

    local set_task_matches
    set_task_matches() {
      if test $1 = POSITIONAL; then
        case $2 in
        0)
          PATH=$path print_tasks | tr '\n' ' '
          ;;
        1)
          echo "$targets"
          ;;
        esac
      fi
    }

    local info_matches
    info_matches() {
      if test $1 = POSITIONAL -a $2 = 0; then
        PATH=$path print_tasks | tr '\n' ' '
      fi
    }

    local remove_task_matches
    remove_task_matches() {
      if test $param_type = POSITIONAL; then
        PATH=$path print_tasks | tr '\n' ' '
      fi
    }

    local set_branch_matches
    set_branch_matches() {
      if test $1 = POSITIONAL -a $2 = 0; then
       PATH=$path print_branches | tr '\n' ' '
      fi
    }

    local set_target_matches
    set_target_matches() {
      if test $1 = POSITIONAL -a $2 = 0; then
        echo "$targets"
      fi
    }

    local install_compiler_matches
    install_compiler_matches() {
      if test $1 = POSITIONAL -a $2 = 0; then
        echo "$configs"
      fi
    }

    local run_lit_tests_matches
    run_lit_tests_matches() {
      if test $1 = VALUE -a \( $2 = -o -o $2 = --opt \) ; then
        echo "$opts"
      else
        install_compiler_matches "$@"
      fi
    }

    local cd_matches
    cd_matches() {
      if test $1 = POSITIONAL -a $2 = 0; then
        case $1 in
        T@*)
          # TODO: T@ $/...
          ;;
        *)
          PATH=$path $helpers/print_cd_targets
          ;;
        esac
      elif test $1 = VALUE -a \( $2 = -n -o $2 = --ninja \) ; then
        echo "$configs"
      fi
    }

    local vim_matches
    vim_matches() {
      if test $1 = POSITIONAL -a $2 = 0; then
        PATH=$path $helpers/print_vim_targets
      elif test $1 = VALUE -a \( $2 = -n -o $2 = --ninja \) ; then
        echo "$configs"
      fi
    }

    local open_spec_matches
    open_spec_matches() {
      if test $1 = POSITIONAL -a $2 = 0; then
        cv open-spec list list
      fi
    }

    local update_matches
    update_matches() {
      if test $1 = POSITIONAL; then
        if test -n "${XYZ_TASK:-}" && PATH=$path $helpers/is_llvm_task "${XYZ_TASK:-}"; then
          (cd $XYZ_LLVM_SOURCE && ls -1d */.git | sed 's!\/\.git$!!')
        fi
      fi
    }

    local zip_tools_matches
    zip_tools_matches() {
      if test $1 = POSITIONAL -a $2 = 0; then
        echo "$targets"
      fi
    }

    local download_rc_matches
    download_rc_matches() {
      if test $1 = POSITIONAL -a -n "${XYZ_TARGET:-}"; then
        case $2 in
        0)
          PATH=$path python $(cygpath -m $helpers/get_rc_link.py) --list $XYZ_TARGET | sed 's/^\([^ ]*\) .*/\1/' | tr '\n' ' '
          ;;
        1)
          echo $targets
          ;;
        esac
      fi
    }

    local diff_tasks_matches
    diff_tasks_matches() {
      if test $1 = POSITIONAL; then
        case $2 in
        0 | 1)
          PATH=$path print_tasks | tr '\n' ' '
          ;;
        esac
      fi
    }

    # TODO: other commands

    local matches=
    if test $COMP_CWORD = 1; then
      matches=$( (cd $(dirname $BASH_SOURCE) && ls -1 *.sh) | sed 's/\.sh$//' | tr '\n' ' ' )
    else
      cmd=${COMP_WORDS[1]}
      cmd_=$(echo $cmd | tr '-' '_')
      if echo ${COMP_WORDS[COMP_CWORD]} | grep -q '^-'; then
        matches=$(PATH=$path get_flags $cmd)
      else
        cmd_=$($helpers/get_cmd_alias $cmd_ | tr '-' '_')
        if declare -fp ${cmd_}_matches > /dev/null 2>&1; then
          # Get more detailed info about autocompleted parameter
#          echo >&2 "Calling analyze_autocomplete $COMP_CWORD ${COMP_WORDS[*]}"
          local res=$(PATH=$path analyze_autocomplete $COMP_CWORD ${COMP_WORDS[*]})
          local param_type=${res% *}
          local param_info=${res#* }
#          echo >&2 "analyze_autocomplete: $param_type $param_info"
          matches=$(${cmd_}_matches $param_type $param_info)
        fi
      fi
    fi

    if test -n "${matches:-}"; then
      COMPREPLY=( $(compgen -W "$matches" -- ${COMP_WORDS[COMP_CWORD]}) )
      return 0
    fi

    return 1
  }

  complete -F _XYZAutoComplete -o default cv
else
  shift
  if grep -q 'cv.*install-auto-complete.sh DODODO' ~/.bashrc; then
    echo >&2 "error: auto-completion already installed in $HOME/.bashrc"
    exit 1
  fi
  echo "source $BASH_SOURCE DODODO  # Autogenerated" >> ~/.bashrc
fi

