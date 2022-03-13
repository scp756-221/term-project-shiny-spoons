#!/usr/bin/env bash
# Set AWS configuration and CMPT 756 token file directly 
# with no intervening file.
#
# When these conditions are met, this approach is more
# secure as the access key ID and the secret access key itself
# are neither displayed on the console nor saved in a second file.
# Note that these two values of necessity *are* saved in the
# files "~/.aws/credentials" and "cluster/tpl-vars.txt".
#
# User must have exactly one access key.

# For bash tips, see https://devhints.io/bash 

# Strict mode (because this is security-sensitive)
set -o nounset
set -o errexit
set -o pipefail
IFS=$'\n\t'

usage() {
  cat <<EOF
Usage: ${0}
Create a second AWS access key and make it the current key.

Prerequisites:
* The user must already have an active access key and be signed in to
  the AWS command-line with it
* The user must not have any other access key (whether
  active or inactive).

If the user has an older access key, they must first set it to
"Inactive" and then delete it before running this script.
EOF
}

if [[ $# -ne 0 ]]
then
  usage
  exit 1
fi

# Count number of keys (active and inactive) for this user
key_count=$(aws iam list-access-keys --output json | jq '.AccessKeyMetadata | length') || true

if [[ $? -ne 0 ]]
then
  cat <<EOF
The query of your key count failed, likely because you are not
signed in to the AWS command line with an active access key.

Use the AWS Console to set up a valid, active key. Then download
that key as a CSV and use "tools/aws-cred.sh" to set your access.
EOF
  exit 1
elif [[ ${key_count} -ge 2 ]]
then
  cat <<EOF
You have two keys already.  One must be set "Inactive" and deleted
before running this script.
EOF
  exit 2
fi

key_id_value=$(aws iam create-access-key --output json | jq '.AccessKey | .AccessKeyId, .SecretAccessKey')

# Next line just for testing
#key_id_value=$(cat test.json | jq '.AccessKey | .AccessKeyId, .SecretAccessKey')

# key_id_value has format "20-char-key-id" "40-char-key-value"
aws_id=${key_id_value:1:20}
aws_key=${key_id_value:24:40}

# Configure the AWS command-line tools
aws configure set aws_access_key_id     ${aws_id}
aws configure set aws_secret_access_key ${aws_key}

# Configure the CMPT 756 files
# The official AWS docs
# (https://docs.aws.amazon.com/IAM/latest/APIReference/API_AccessKey.html)
# state that Access Key IDs are pure alphanumeric.
# They do not restrict the Secret Access Key in any way but various
# sites on the Web suggest that it is only alphanumeric+slash+plus
# So it should be delimitable by '|'
sed -e "s|ZZ-AWS-ACCESS-KEY-ID=.*|ZZ-AWS-ACCESS-KEY-ID=${aws_id}|"           \
    -e "s|ZZ-AWS-SECRET-ACCESS-KEY=.*|ZZ-AWS-SECRET-ACCESS-KEY=${aws_key}|"  \
  -i cluster/tpl-vars.txt
