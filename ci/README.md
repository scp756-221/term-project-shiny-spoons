# Continuous integration framework

This directory contains the continuous integration (CI) framework. It includes the files used by GitHub Actions to accomplish CI, the files defining different versions of the tests, as well as other files useful for locally running CI tests.

## Automated CI

The automatic CI is defined by the following GitHub Action files:

* `../.github/workflows/ci-system-v*.yaml`: GitHub Action Specification of systemic CI using a local DynamoDB for a given version.

The top level of the CI is run by:

* `runci.sh`: The script calling `docker-compose` to spin up the instances of the S1, S2, DB, and test services, together with a local copy of DynamodB. It takes an optional argument, specifying the subdirectory defining the test to run.  The default value of this argument is `v1`.  **If you want to run a test locally, you probably want to use `runci-local.sh`, described below.**

### Versioning the tests

The tests are defined in subdirectories, one for each version. Amongst other files, each version subdirectory contains:

* `compose-tpl.yaml`: Specification of the service configuration to run; templated file&mdash;see below.
* `Dockerfile`: Container specification.
* `requirements.txt`: List of Python packages to include.
* `conftest.py`: `pytest` test fixtures that to be shared across all test files.
* `test_*.py`: Test files. Any file with this prefix is a `pytest` test file and will be run in the test.
* `create_tables.py`: Library to create the DynamoDB tables.
* `music.py`: Python client library for the music service. Definition of a corresponding `user.py` for the user service is left as an exercise.

The three application services, S1, S2, and DB, are defined in their respective directories. The appropriate directories are specified in `compose-tpl.yaml`.

## Running CI locally

A simple script, `runci-local.sh`, is provided. Use this script to test changes to the CI test before pushing it to GitHub.  This script is "safe", in the sense that it completely rebuilds every image for every service on every run.  If you want to speed up your test runs, you may want to use your own script to selectively build only services that have changed.

### Image names from local tests

When running CI tests locally, whether by `runci.sh` or `runch-local.sh` (or any script that uses `compose.yaml`), the following image names are created:

* `ci_db:latest`
* `ci_s1:latest`
* `ci_s2:latest`
* `ci_test:latest`

You will probably want to remove these (via `docker image rm`) once you are done.

## Templated files

The file input to `docker-compose` is templated.  The reference version is `compose-tpl.yaml`. Make all modifications to that file, then run

~~~bash
/home/k8s/ci# cd ..
/home/k8s# make -f k8s-tpl.mak templates
~~~

to regenerate the `compose.yaml` file that will actually define the test.

**Do not directly modify `compose.yaml`.  Only modify `compose-tpl.yaml` and run `make` to regenerate `compose.yaml`.**

## Utility scripts

The following scripts are simple utilities that may prove useful:

* `create-local-tables.sh`: Create the two DynamoDB tables in a local instance. This does not have to be done for a regular test, in which the Python code creates the tables.  But when running manual tests, you may use this script to create the tables.
* `quick-test.sh`: A quick test of a running system, this creates a single song on the music table.  Because the music system accepts multiple "creates" of the same song (giving each instance a different UUID), you can call this multiple times without error.
