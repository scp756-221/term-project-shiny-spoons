#!/usr/bin/env bash
set -o nounset
set -o errexit
if [[ $# -gt 1 ]]; then
  echo "Usage: ${0} [IP-ADDRESS]"
  echo "Quick system test: Create 'Duran Duran', 'Rio'"
  echo "  Default IP address: 0.0.0.0"
  echo "  Port is always 30001"
  echo
  echo "Use this for a quick test that docker-compose"
  echo "brought at least the music service up. It creates"
  echo "a single song." 
  exit 1
elif [[ $# -eq 1 ]]; then
  ip=${1}
else
  ip=0.0.0.0
fi
set -o xtrace
curl --location --request POST "http://${ip}:30001/api/v1/music/" \
  --header 'Authorization: Bearer eyJ0eX' \
  --header 'Content-Type: application/json' \
  --data-raw '{ "Artist": "Duran Duran", "SongTitle": "Rio" }'
