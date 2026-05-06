#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BATS_DIR="$REPO_ROOT/test/bats-core"

if [ -d "$BATS_DIR" ]; then
    echo "bats-core already installed at $BATS_DIR"
    exit 0
fi

echo "Installing bats-core..."
git clone --depth 1 https://github.com/bats-core/bats-core.git "$BATS_DIR"
echo "Done. Run tests with:"
echo "  $BATS_DIR/bin/bats test/unit/"
echo "  $BATS_DIR/bin/bats test/integration/"
