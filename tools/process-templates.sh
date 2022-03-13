#!/usr/bin/env bash
#
# Instantiate templates into configuration files
# Most of the work is done in sub-script `call-sed.sh`.
#
# Step 0: Check that necessary tools are in command path
#
function check_command () {
  which ${1} >> /dev/null
  if [[ $? -ne 0 ]]
  then
    echo "Warning: ${1} is not in the search path"
  fi
}
check_command 'kubectl'
check_command 'istioctl'
check_command 'helm'
check_command 'curl'
# AWS command is required for all vendors, to control DynamoDB
check_command 'aws'
#
# Step 0: Check that the input file exists
#
if [[ ! -f cluster/tpl-vars.txt ]]; then
  echo "Create and fill in file 'cluster/tpl-vars.txt' before running this command."
  exit 1
fi
#
# Step 1: Strip comments from file listing variables
#
grep -v '^#' ./cluster/tpl-vars.txt > ./cluster/tpl-nocomments.txt
#
# Step 2: Check that every field has a value
#
vals=$(cut -f 2 -d= ./cluster/tpl-nocomments.txt)
count_vals () {
  echo $#
}
if [[ `count_vals ${vals}` -ne 5 ]]; then
  echo "Some fields in 'cluster/tpl-vars.txt' are not filled in."
  exit 1
fi
#
# Step 3: Convert the files
#
find . -name '*-tpl.*' -exec ./tools/call-sed.sh '{}'  ${vals} \;
#
# Step 3: Cleanup
#
/bin/rm -f ./cluster/tpl-nocomments.txt
