#!/usr/bin/env bash
set -euo pipefail

# Ensure we're running from repo root
cd "$(dirname "$0")/../../" || true

echo "=== Testing Database File Validation in qb-services-stop.sh ==="

export INV=$(mktemp)
echo '{"data":[]}' > "$INV"
export DB="/tmp/nonexistent_db_test_$$.db"

if ./resources/migration/qb-services-stop.sh 2> /tmp/err_out_stop; then
    echo "ERROR: Expected qb-services-stop.sh to fail with missing DB"
    rm -f "$INV" /tmp/err_out_stop
    false
fi

if ! grep -q "QuickBox DB not found" /tmp/err_out_stop; then
    echo "ERROR: Expected specific error message for missing DB. Got:"
    cat /tmp/err_out_stop
    rm -f "$INV" /tmp/err_out_stop
    false
fi

echo "[✓] Database validation test passed"
rm -f "$INV" /tmp/err_out_stop
