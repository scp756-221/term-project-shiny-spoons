#!/usr/bin/env bash
# If a specified command exists, run a makefile that calls it
if [[ $# -lt 2 ]]; then
  echo "Usage: ${0} COMMAND ARGUMENTS*"
  echo "If COMMAND exists, run make with ARGUMENTS"
  echo
  echo "  COMMAND can be an executable file, an alias, or a bash function."
  echo "  ARGUMENTS is the sequence of arguments passed to make."
  exit 1
fi

if [[ `type -t "${1}"` != '' ]]; then
  shift
  make "$@"
else
  echo "Command '${1}' not found.  Skipping this step."
fi
