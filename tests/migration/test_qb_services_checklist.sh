#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../../" || true

echo "=== Testing has_unit Function in qb-services-checklist.sh ==="

export INV=$(mktemp)
echo '{"data":[]}' > "$INV"

export DB=$(mktemp)
touch "$DB"

sqlite3() {
    return 0
}
export -f sqlite3

systemctl() {
    if [[ "$1" == "list-unit-files" ]]; then
        echo "nginx.service"
        echo "qbwsd.service"
        echo "ttyd@.service"
    elif [[ "$1" == "list-units" ]]; then
        echo "nginx.service"
        echo "ttyd@jules.service"
    fi
}
export -f systemctl

jq() {
    return 0
}
export -f jq

source ./resources/migration/qb-services-checklist.sh >/dev/null

if ! has_unit "nginx.service"; then
    echo "ERROR: has_unit failed for existing unit (nginx.service)"
    false
fi

if has_unit "missing.service"; then
    echo "ERROR: has_unit succeeded for missing unit (missing.service)"
    false
fi

echo "[✓] has_unit test passed"

rm -f "$INV" "$DB"
