#!/usr/bin/env bash
#
# health-check.sh - Docker HEALTHCHECK probe for the diagnostic CLI.
# Succeeds (exit 0) if the diagnostic tool responds correctly to 'help'.
#
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if "$SCRIPT_DIR/diagnostic.sh" help >/dev/null 2>&1; then
    exit 0
else
    exit 1
fi
