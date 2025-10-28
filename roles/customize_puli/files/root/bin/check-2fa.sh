#!/bin/bash

# check-2fa.sh
# This script checks which valid users are missing a Google Authenticator configuration.

REPORT_FILE="/var/log/2fa_check.log"
DATE=$(date "+%Y-%m-%d %H:%M:%S")

echo "[$DATE] Starting 2FA check..." >> "$REPORT_FILE"

# Get list of valid (non-system) users with normal shells
getent passwd | awk -F: '($3 >= 1000 && $7 !~ /(nologin|false)$/) {print $1}' | while read -r user; do
    # Skip locked or expired accounts
    if passwd -S "$user" | grep -qE 'L|LK|NP'; then
        continue
    fi

    HOME_DIR=$(getent passwd "$user" | cut -d: -f6)
    if [ ! -f "$HOME_DIR/.google_authenticator" ]; then
        echo "User $user has no .google_authenticator file" >> "$REPORT_FILE"
    fi
done

echo "[$DATE] 2FA check complete." >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
