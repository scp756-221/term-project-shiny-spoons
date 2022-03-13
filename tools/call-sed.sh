#!/usr/bin/env bash
# Process the template variables for a single file.
# The first argument is the name of the file to process. It must include `-tpl` 
# The remaining arguments must exactly match the order of variable names
# in the `sed` expression below.
#
set -o nounset
set -o errexit
if [[ $# -ne 6 ]]
then
  echo "call-sed.sh must have six arguments"
  exit 1
fi
#
# Create output file name
#
out=${1/-tpl/}
#
# Replace all the variables
# The official AWS docs (https://docs.aws.amazon.com/IAM/latest/APIReference/API_AccessKey.html) state that Access Key IDs are pure alphanumeric.
# They do not restrict the Secret Access Key in any way but various sites on the Web suggest that it is only alphanumeric+slash+plus
# So it should be delimitable by '|'
sed -e "s|ZZ-CR-ID|${2}|g" -e "s|ZZ-REG-ID|${3}|g" -e "s|ZZ-AWS-REGION|${4}|g" -e "s|ZZ-AWS-ACCESS-KEY-ID|${5}|g" -e "s|ZZ-AWS-SECRET-ACCESS-KEY|${6}|g" ${1} > ${out}
# If source file is executable, output should be, too.
# BUT in a container, `test -x` doesn't work correctly some times, such
# as when Host OS is macOS. So use this clumsy alternative, which works (sigh)
function is_executable () {
  user_perms=$(ls -l ${1})
  if [[ "${user_perms:3:1}" == x ]]; then
    return 0
  else
    return 1
  fi
}
if is_executable ${1}; then
  chmod +x ${out}
fi