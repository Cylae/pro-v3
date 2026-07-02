#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECKLIST_SCRIPT="${SCRIPT_DIR}/../../resources/migration/qb-services-checklist.sh"

echo "Running tests for $CHECKLIST_SCRIPT"

# Source the script. The main logic is protected by if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
source "$CHECKLIST_SCRIPT"

test_has_unit() {
    echo "  Testing has_unit..."
    # Clear and set up HAS array
    unset HAS
    declare -g -A HAS
    HAS["nginx.service"]=1
    HAS["php7.4-fpm.service"]=1

    if ! has_unit "nginx.service"; then
        echo "    ❌ Failed: Expected has_unit 'nginx.service' to be true"
        return 1
    fi

    if has_unit "apache2.service"; then
        echo "    ❌ Failed: Expected has_unit 'apache2.service' to be false"
        return 1
    fi
    echo "    ✅ Passed has_unit"
}

test_has_template() {
    echo "  Testing has_template..."
    unset HAS
    declare -g -A HAS
    HAS["rtorrent@.service"]=1

    if ! has_template "rtorrent"; then
        echo "    ❌ Failed: Expected has_template 'rtorrent' to be true"
        return 1
    fi

    if has_template "qbwsd"; then
        echo "    ❌ Failed: Expected has_template 'qbwsd' to be false"
        return 1
    fi
    echo "    ✅ Passed has_template"
}

test_has_instance() {
    echo "  Testing has_instance..."
    unset HAS
    declare -g -A HAS
    HAS["rtorrent@user1.service"]=1

    if ! has_instance "rtorrent" "user1"; then
        echo "    ❌ Failed: Expected has_instance 'rtorrent' 'user1' to be true"
        return 1
    fi

    if has_instance "rtorrent" "user2"; then
        echo "    ❌ Failed: Expected has_instance 'rtorrent' 'user2' to be false"
        return 1
    fi

    if has_instance "deluged" "user1"; then
        echo "    ❌ Failed: Expected has_instance 'deluged' 'user1' to be false"
        return 1
    fi
    echo "    ✅ Passed has_instance"
}

# Run tests
FAILURES=0

test_has_unit || FAILURES=$((FAILURES+1))
test_has_template || FAILURES=$((FAILURES+1))
test_has_instance || FAILURES=$((FAILURES+1))

if [ "$FAILURES" -gt 0 ]; then
    echo "$FAILURES test(s) failed."
    # We will exit later
    exit 1
else
    echo "All tests passed successfully!"
fi
