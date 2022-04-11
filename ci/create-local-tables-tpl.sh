#!/usr/bin/env bash
# Create tables in local DynamoDB
set -o nounset
set -o errexit
set -o xtrace
# Note that the `region` and `provisioned-throughput` parameters 
# are required by the CLI
# but ignored for this local version of DynamoDB.
aws dynamodb create-table \
  --endpoint-url http://0.0.0.0:8000 \
  --region us-west-2 \
  --table-name Music-ZZ-REG-ID \
  --attribute-definitions '[{ "AttributeName": "music_id", "AttributeType": "S" }]' \
  --key-schema '[{ "AttributeName": "music_id", "KeyType": "HASH" }]' \
  --provisioned-throughput '{"ReadCapacityUnits": 5, "WriteCapacityUnits": 5}'
aws dynamodb create-table \
  --endpoint-url http://0.0.0.0:8000 \
  --region us-west-2 \
  --table-name User-ZZ-REG-ID \
  --attribute-definitions '[{ "AttributeName": "user_id", "AttributeType": "S" }]' \
  --key-schema '[{ "AttributeName": "user_id", "KeyType": "HASH" }]' \
  --provisioned-throughput '{"ReadCapacityUnits": 5, "WriteCapacityUnits": 5}'

