#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Cleaning test artifacts..."

rm -rf "$REPO_ROOT/test/bats-core"
echo "  removed test/bats-core/"

find /tmp -maxdepth 1 -type d -name 'tmp.*' -mmin +60 -exec rm -rf {} + 2>/dev/null || true
echo "  removed stale temp dirs"

if [ "${1:-}" = "--docker" ]; then
    docker rmi sbox 2>/dev/null && echo "  removed image sbox" || true
    docker volume rm sbox-auth sbox-data 2>/dev/null && echo "  removed volumes sbox-auth sbox-data" || true
fi

echo "Done."
