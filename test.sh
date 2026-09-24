#!/usr/bin/env bash
#
# test.sh - Test suite for the Dockerized diagnostic CLI image.
# Builds (if needed) and exercises the image: help, system, disk, and
# invalid-command handling.
#
set -u

IMAGE="${DIAGNOSTIC_TEST_IMAGE:-diagnostic-tool-test}"
PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

echo "======================================"
echo " Assignment 2 - Docker Image Tests"
echo "======================================"
echo

if ! command -v docker >/dev/null 2>&1; then
    echo "ERROR: Docker is required to run these tests."
    exit 2
fi

echo "Building image '$IMAGE' ..."
if docker build -t "$IMAGE" . >/tmp/assignment2-test-build.log 2>&1; then
    pass "Docker image builds successfully"
else
    fail "Docker image failed to build"
    cat /tmp/assignment2-test-build.log
fi

run_case() {
    local name="$1"; shift
    local expect_zero="$1"; shift
    if "$@" >/tmp/assignment2-test-run.log 2>&1; then
        rc=0
    else
        rc=$?
    fi
    if [[ "$expect_zero" == "yes" && $rc -eq 0 ]]; then
        pass "$name (exit $rc)"
    elif [[ "$expect_zero" == "no" && $rc -ne 0 ]]; then
        pass "$name (exit $rc)"
    else
        fail "$name (exit $rc)"
        cat /tmp/assignment2-test-run.log
    fi
}

run_case "help command succeeds"            yes docker run --rm "$IMAGE" help
run_case "system command succeeds"          yes docker run --rm "$IMAGE" system
run_case "disk command succeeds"            yes docker run --rm "$IMAGE" disk
run_case "invalid command fails (non-zero)" no  docker run --rm "$IMAGE" totally-invalid-command
run_case "missing network host fails"       no  docker run --rm "$IMAGE" network
run_case "network with host succeeds"       yes docker run --rm "$IMAGE" network localhost

docker image rm "$IMAGE" >/dev/null 2>&1 || true

echo
echo "======================================"
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo "======================================"

[[ $FAIL -eq 0 ]]
