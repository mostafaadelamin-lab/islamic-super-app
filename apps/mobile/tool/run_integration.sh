#!/usr/bin/env bash
# Runs the device integration tests with a hard time limit. The Android emulator in
# CI occasionally hangs after installing the APK (no test output at all). One retry
# is allowed for that infrastructure hang only; every attempt is logged, and a test
# that *fails* (rather than hangs) is not retried.
set -u
cd "$(dirname "$0")/.."
for attempt in 1 2; do
  echo "::group::integration_test attempt $attempt"
  timeout 600 flutter test integration_test --reporter expanded "$@"
  code=$?
  echo "::endgroup::"
  if [ $code -eq 0 ]; then echo "integration tests passed on attempt $attempt"; exit 0; fi
  if [ $code -ne 124 ]; then echo "integration tests FAILED (exit $code) on attempt $attempt"; exit $code; fi
  echo "::warning::integration tests hung (timeout) on attempt $attempt"
done
exit 1
