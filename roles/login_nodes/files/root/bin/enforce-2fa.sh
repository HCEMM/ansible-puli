#!/bin/bash

# enforce-2fa.sh
# Enforce that all valid users have Google Authenticator (2FA) configured.
# If not, their account will be locked automatically.

REPORT_FILE="/var/log/2fa_check.log"
DATE=$(date "+%Y-%m-%d %H:%M:%S")

echo "[$DATE] Starting 2FA compliance check..." >> "$REPORT_FILE"

# Enumerate normal users (UID >= 1000, with a valid shell)
getent passwd | awk -F: '($3 >= 1000 && $7 !~ /(nologin|false)$/) {print $1}' | while read -r user; do
    # Skip expired or already locked accounts
    STATUS=$(passwd -S "$user" | awk '{print $2}')
    if [[ "$STATUS" =~ ^(L|LK|NP)$ ]]; then
        continue
    fi

    HOME_DIR=$(getent passwd "$user" | cut -d: -f6)
    GA_FILE="$HOME_DIR/.google_authenticator"

    if [ ! -f "$GA_FILE" ]; then
        echo "[$DATE] User '$user' missing .google_authenticator — locking account." >> "$REPORT_FILE"
        passwd -l "$user" &>/dev/null
    else
        echo "[$DATE] User '$user' has 2FA configured." >> "$REPORT_FILE"
    fi
done

echo "[$DATE] 2FA compliance check completed." >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
