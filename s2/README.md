# CMPT 756 Music service

The music service maintains a list of songs and the artists that performed
them.

This is a public Flask server written in Python.

There are several versions, each in its own subdirectory:

standalone: A version that maintains its database internally
  and does not require any other services to run. It includes
  the "bug" explored in Assignments 1--3, where the `test`
  request causes a stack trace if the correct code is
  not embedded in the program.

v1: A version that relies upon the DB service to store its
  values persistently. This version is typically used as
  the "bug" version in Assignment 4, using the "bug"
  described for "standalone" above.

v1.1: A version specifically for Assignment&nbsp;7.  See the `README.md` in the subdirectory and the assignment description for further details.

v2: This version is configurable to return errors for a specified
  percentage (`PERCENT_ERROR`) of calls to `read`. It does not
  include the "bug" in in Assignment 4.  The `test` call
  will always return Success.

  This version is typically used with some form of
  traffic shaping to demonstrate "canary" deployments and
  rollbacks. See `cluster/s2-vs-canary.yaml` for setting
  up the services for such a deployment.

test: A special test frontend.  Used in the continuous
  integration tests for early assignments. May also be used for local unit
  testing.
