#!/usr/bin/env bash
# Set AWS configuration and CMPT 756 token file from 
# a CSV downloaded from Amazon

# For bash tips, see https://devhints.io/bash 

# Strict mode (because this is security-sensitive)
set -o nounset
set -o errexit
set -o pipefail
IFS=$'\n\t'

usage() {
  cat <<EOF
Usage: ${0} AWS-CSV
Configure AWS and the CMPT 756 software to use a new access key.

AWS-CSV is a '.csv' file directly downloaded from AWS,
  containing a currently-active access key. This file
  should be completely deleted or stored in a safe directory
  after running this script.
EOF
}

if [[ $# -ne 1 || "${1}" == "-h" || "${1}" == "--help" ]]
then
  usage
  exit 1
fi

if [[ "${1:(-4):4}" != ".csv" ]]
then
  echo "Filename ${1} does not have '.csv' extension."
  exit 1
fi

# Count number of keys (active and inactive) for this user
# aws iam list-access-keys --output json | jq '.AccessKeyMetadata | length'

# Be extremely particular about format of access key id and value
awshead='Access key ID,Secret access key'
id_min_len=20
key_min_len=40

# AWS credential files are in DOS format, with extraneous '\r'
header=$( head -1 ${1} | tr -d \\r )
aws_id=$( tail -1 ${1}             | cut -f 1 -d , )
aws_key=$(tail -1 ${1} | tr -d \\r | cut -f 2 -d , )

if [[ "${header}" != ${awshead} ]]
then
  echo "Header line .${header}. is not '${awshead}'"
  exit
fi

if [[ ${#aws_id} -lt ${id_min_len} ]]
then
  echo "ID (first field of second line in ${1}) is less than ${id_min_len} characters long."
  exit 1
fi

if [[ ${#aws_key} -lt ${key_min_len} ]]
then
  echo "Key (second field of second line in ${1}) is less than ${key_min_len} characters long."
  exit 1
fi

# Configure the AWS command-line tools
aws configure set aws_access_key_id     ${aws_id}
aws configure set aws_secret_access_key ${aws_key}

# Configure the CMPT 756 files
# The official AWS docs (https://docs.aws.amazon.com/IAM/latest/APIReference/API_AccessKey.html) state that Access Key IDs are pure alphanumeric.
# They do not restrict the Secret Access Key in any way but various sites on the Web suggest that it is only alphanumeric+slash+plus
# So it should be delimitable by '|'
sed -e "s|ZZ-AWS-ACCESS-KEY-ID=.*|ZZ-AWS-ACCESS-KEY-ID=${aws_id}|"           \
    -e "s|ZZ-AWS-SECRET-ACCESS-KEY=.*|ZZ-AWS-SECRET-ACCESS-KEY=${aws_key}|"  \
  -i cluster/tpl-vars.txt
