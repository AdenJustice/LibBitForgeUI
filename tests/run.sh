#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob
cd "$(dirname "$0")/.."
status=0
for file in tests/test_*.lua; do
    echo "== $file"
    lua "$file" || status=1
done
exit $status
