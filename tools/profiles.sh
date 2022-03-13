#!/usr/bin/env bash
# You want to `source` this script, not execute it:
#   /home/k8s# . tools/profiles.sh
# This will define the bash aliases in the current shell.
# Copy profiles into tools container
if [[ -e profiles/bash_aliases ]]; then
  /usr/bin/cp -f profiles/bash_aliases ~/.bash_aliases
fi
if [[ -e profiles/gitconfig ]]; then
  /usr/bin/cp -f profiles/gitconfig ~/.gitconfig
fi
# Now source the bash aliases so this shell also has them
source ~/.bash_aliases
