#!/usr/bin/env bash
# Runs the device integration tests with a hard time limit. The Android emulator in
# CI occasionally hangs after installing the APK (no test output at all). One retry
# is allowed for that infrastructure hang only; every attempt is logged, and a test
# that *fails* (rather than hangs) is not retried.
set -u
cd "$(dirname "$0")/.."

# Portable time limit (macOS runners have no GNU `timeout`): exit 124 on expiry.
run_limited() {
  local limit=$1; shift
  "$@" &
  local pid=$!
  ( sleep "$limit" && touch .integration_timed_out && kill -TERM "$pid" 2>/dev/null ) &
  local watcher=$!
  wait "$pid"; local code=$?
  kill "$watcher" 2>/dev/null; wait "$watcher" 2>/dev/null
  if [ -f .integration_timed_out ]; then rm -f .integration_timed_out; return 124; fi
  return $code
}
for attempt in 1 2; do
  echo "::group::integration_test attempt $attempt"
  run_limited 600 flutter test integration_test --reporter expanded "$@"
  code=$?
  echo "::endgroup::"
  if [ $code -eq 0 ]; then echo "integration tests passed on attempt $attempt"; exit 0; fi
  if [ $code -ne 124 ]; then echo "integration tests FAILED (exit $code) on attempt $attempt"; exit $code; fi
  echo "::warning::integration tests hung (timeout) on attempt $attempt"
done
exit 1
