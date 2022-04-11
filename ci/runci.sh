#!/usr/bin/env bash
# Build and run the CI test
# This is intended to be run in a fresh environment,
# such as a GitHub action, where no prior
# images exist.  If you want to test your CI locally,
# use `runci-local.sh` instead.
set -o errexit
set -o nounset

if [[ $# -gt 1 ]]; then
  echo "Usage: ${0} [VERSION]"
  echo "Run the continuous integration tests"
  echo
  echo "  VERSION the version subdirectory of the test code (v1, ...)"
  echo "  default: v1"
  echo
  echo "  Environment variable COMPOSE_PATH, if defined, specifies the path used"
  echo "  to invoke docker-compose v2.  If not defined, the path is searched"
  echo "  for docker-compose. This variable is typically unset for local runs"
  echo "  and only set in GitHub actions, where we need to guarantee the version"
  echo "  of docker-compose we're using."
  exit 1
elif [[ $# -eq 1 ]]; then
  ver="${1}"
else
  ver=v1
fi

if [[ ! -d ${ver} ]]; then
  echo "'${ver}' is not a subdirectory of the current directory"
  exit 2
fi

COMP=${COMPOSE_PATH:-docker-compose}

# First, a syntax, style, and poor usage check
# Nonconforming code will cause a CI fail
#
# Turn off errexit so we can give a better message on fail
set +o errexit
echo
echo "Checking flake8 conformance ..."
flake8 $(cat ${ver}/flake-dirs.txt)
if [[ $? -eq 0 ]]; then
  echo
  echo "Code conforms."
else
  echo
  echo "Code does not conform---CI fails."
  exit 1
fi
set -o errexit

set -o xtrace
# Turn off errexit so we continue even if CI test returns failure
set +o errexit
${COMP} -f ${ver}/compose.yaml up --build --abort-on-container-exit --exit-code-from test
# Return code from 'up' is the test result
trc=$?
# Shutdown and delete all the containers before returning
${COMP} -f ${ver}/compose.yaml down
exit ${trc}
