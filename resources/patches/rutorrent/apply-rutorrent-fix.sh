#!/bin/bash
################################################################################
# ruTorrent i8 Detection Fix for rtorrent 0.16.x+
#
# This script patches ruTorrent to fix compatibility issues with rtorrent 0.16.0+
# including the false "without i8 support" error and ratio plugin failures.
#
# Issue: https://github.com/Novik/ruTorrent/issues/2983
# Root cause: ruTorrent tests for i8 support using deprecated 'to_kb' command
#             which was removed in rtorrent 0.16.0. rtorrent 0.16.0+ has i8
#             support built-in (mandatory), so the test is obsolete.
#
# What this script does:
#   1. Locates your ruTorrent installation
#   2. Creates backups of settings.php
#   3. Applies patch to skip obsolete i8 test for rtorrent 0.16.0+
#   4. Verifies the fix was applied correctly
#
# Usage: sudo ./apply-rutorrent-fix.sh [--dry-run]
################################################################################

set -e

# Parse arguments
DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "DRY RUN MODE - No changes will be made"
    echo ""
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
echo_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
echo_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
echo_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if running as root
if [[ ${EUID} -ne 0 ]]; then
    echo_error "This script must be run as root (sudo)"
    exit 1
fi

# Find ruTorrent installation
RUTORRENT_PATH=""
for path in /srv/rutorrent /var/www/rutorrent /usr/share/nginx/html/rutorrent /var/www/html/rutorrent; do
    if [[ -f "${path}/php/settings.php" ]]; then
        RUTORRENT_PATH="${path}"
        break
    fi
done

if [[ -z "${RUTORRENT_PATH}" ]]; then
    echo_error "ruTorrent installation not found in common locations."
    echo "Please specify the path manually:"
    read -r -p "Enter ruTorrent path: " RUTORRENT_PATH

    if [[ ! -f "${RUTORRENT_PATH}/php/settings.php" ]]; then
        echo_error "Invalid path. settings.php not found at: ${RUTORRENT_PATH}/php/settings.php"
        exit 1
    fi
fi

echo_info "Found ruTorrent at: ${RUTORRENT_PATH}"

SETTINGS_FILE="${RUTORRENT_PATH}/php/settings.php"
PATCH_FILE="$(dirname "$0")/rutorrent-rtorrent-0.16.x-i8-fix.patch"

# Check if patch file exists
if [[ ! -f "${PATCH_FILE}" ]]; then
    echo_error "Patch file not found: ${PATCH_FILE}"
    exit 1
fi

# Check if already patched
if grep -q "i8 support detection fix for rtorrent 0.16" "${SETTINGS_FILE}" 2>/dev/null; then
    echo_warning "Patch appears to be already applied!"
    echo_info "Current settings.php already contains the fix."
    exit 0
fi

if [[ "${DRY_RUN}" == true ]]; then
    echo_info "Would create backup: ${SETTINGS_FILE}.backup-<timestamp>"
    echo_info "Would check/create: ${SETTINGS_FILE}.backup-original"
else
    # Create backup
    BACKUP_FILE="${SETTINGS_FILE}.backup-$(date +%Y%m%d-%H%M%S)"
    echo_info "Creating backup: ${BACKUP_FILE}"
    cp "${SETTINGS_FILE}" "${BACKUP_FILE}"

    # Create permanent backup of original if it doesn't exist
    if [[ ! -f "${SETTINGS_FILE}.backup-original" ]]; then
        echo_info "Creating permanent backup: ${SETTINGS_FILE}.backup-original"
        cp "${SETTINGS_FILE}" "${SETTINGS_FILE}.backup-original"
    fi
fi

# Try to apply patch
echo_info "Applying patch..."
cd "${RUTORRENT_PATH}/php"

if [[ "${DRY_RUN}" == true ]]; then
    if patch -p0 --dry-run < "${PATCH_FILE}" >/dev/null 2>&1; then
        echo_success "✓ Patch validation successful! (would apply cleanly)"
    else
        echo_error "Patch validation failed!"
        echo ""
        echo_error "The patch cannot be applied to your settings.php file."
        echo_info "This could happen if:"
        echo "  • You have a heavily modified ruTorrent installation"
        echo "  • Your ruTorrent version is very old or very new"
        echo "  • The file has already been manually edited"
        echo ""
        echo_info "Run without --dry-run to see detailed error output"
        exit 1
    fi
else
    # Apply patch for real
    if patch -p0 < "${PATCH_FILE}" 2>&1; then
        echo_success "✓ Patch applied successfully!"
    else
        echo_error "Failed to apply patch!"
        echo ""
        echo_error "The patch could not be applied to your settings.php file."
        echo_info "Possible reasons:"
        echo "  • Your ruTorrent version has a different settings.php structure"
        echo "  • The file has been heavily customized"
        echo "  • The line numbers don't match (different ruTorrent version)"
        echo ""
        echo_info "Restoring backup..."
        cp "${BACKUP_FILE}" "${SETTINGS_FILE}"
        echo_info "Original file restored from: ${BACKUP_FILE}"
        echo ""
        echo_error "Please report this issue with:"
        echo "  • Your ruTorrent version"
        echo "  • Lines 228-240 of your settings.php: sed -n '228,240p' ${SETTINGS_FILE}"
        exit 1
    fi
fi

if [[ "${DRY_RUN}" == true ]]; then
    echo ""
    echo_success "✓ Dry run completed successfully!"
    echo ""
    echo_info "What would be changed:"
    echo "  • Skip obsolete i8 detection test for rtorrent 0.16.0+ (i8 support is built-in)"
    echo "  • Fix ratio plugin to use group. prefix with empty string target for 0.16.0+"
    echo "  • Add version detection to handle rtorrent 0.15.x vs 0.16.0+ correctly"
    echo "  • Fix the false 'without i8 support' error and ratio plugin failures"
    echo ""
    echo_info "To apply the fix for real, run:"
    echo "  sudo $0"
    exit 0
fi

# Verify the fix
echo_info "Verifying patch application..."
if grep -q "i8 support detection fix for rtorrent 0.16" "${SETTINGS_FILE}" && \
   grep -q "badXMLRPCVersion = false" "${SETTINGS_FILE}"; then
    echo_success "✓ Patch successfully applied and verified!"
    echo ""
    echo_info "What was fixed:"
    echo "  • Skipped obsolete i8 detection test for rtorrent 0.16.0+ (i8 support is built-in)"
    echo "  • Fixed ratio plugin to use group. prefix with empty string target for 0.16.0+"
    echo "  • Added version detection to handle rtorrent 0.15.x vs 0.16.0+ correctly"
    echo "  • Fixed the false 'without i8 support' error and ratio plugin failures"
    echo ""
    echo_info "Next steps:"
    echo "  1. Restart your web server:"
    echo "     systemctl restart nginx    # or: systemctl restart apache2"
    echo "  2. Clear your browser cache and cookies for ruTorrent"
    echo "  3. Reload ruTorrent in your browser"
    echo ""
    echo_success "The i8 error message should now be resolved!"
    echo ""
    echo_info "Backups created:"
    echo "  • Timestamped: ${BACKUP_FILE}"
    if [[ -f "${SETTINGS_FILE}.backup-original" ]]; then
        echo "  • Original: ${SETTINGS_FILE}.backup-original"
    fi
else
    echo_error "Verification failed!"
    echo_info "The patch appeared to apply but verification checks failed."
    echo_info "Restoring backup..."
    cp "${BACKUP_FILE}" "${SETTINGS_FILE}"
    echo_info "Backup restored from: ${BACKUP_FILE}"
    exit 1
fi
