#!/bin/bash

ANNOUNCEMENT_FILE="/etc/announcements.txt"
USER_ANNOUNCEMENT_FILE="$HOME/.last_seen_announcement"
LAST_ANNOUNCEMENT_SEEN=0
CURRENT_DATE=$(date +"%Y-%m-%d")
ONE_WEEK_AGO=$(date -d "$CURRENT_DATE -7 days" +"%s")

# Colors
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m' # No Color

# Get the last announcement number the user has seen, if it exists
if [[ -f "$USER_ANNOUNCEMENT_FILE" ]]; then
    LAST_ANNOUNCEMENT_SEEN=$(cat "$USER_ANNOUNCEMENT_FILE")
fi

# Parse announcements and display new ones
NEW_LAST_ANNOUNCEMENT_SEEN=$LAST_ANNOUNCEMENT_SEEN

while IFS= read -r line; do
    # Skip lines that start with #
    if [[ "$line" =~ ^# ]]; then
        continue
    fi

    ANNOUNCEMENT_NUMBER=$(echo "$line" | cut -d'.' -f1)
    ANNOUNCEMENT_DATE=$(echo "$line" | grep -oP '\[\d{4}-\d{2}-\d{2}\]' | tr -d '[]')
    
    # Convert announcement date to seconds since epoch
    ANNOUNCEMENT_DATE_EPOCH=$(date -d "$ANNOUNCEMENT_DATE" +"%s")

    # Skip announcements older than one week
    if [[ "$ANNOUNCEMENT_DATE_EPOCH" -lt "$ONE_WEEK_AGO" ]]; then
        continue
    fi

    # Only display announcements the user hasn't seen
    if [[ "$ANNOUNCEMENT_NUMBER" -gt "$LAST_ANNOUNCEMENT_SEEN" ]]; then
        ANNOUNCEMENT_TYPE=$(echo "$line" | cut -d'.' -f2 | cut -d' ' -f1)
        ANNOUNCEMENT_TEXT=$(echo "$line" | cut -d' ' -f3-) # Skips the date

        # Display announcements in their respective colors
        if [[ "$ANNOUNCEMENT_TYPE" == "[A]" ]]; then
            echo -e "${YELLOW}[ANNOUNCEMENT] ${ANNOUNCEMENT_TEXT}${NC}"
        elif [[ "$ANNOUNCEMENT_TYPE" == "[W]" ]]; then
            echo -e "${RED}[WARNING] ${ANNOUNCEMENT_TEXT}${NC}"
        fi

        # Update the last seen announcement number
        NEW_LAST_ANNOUNCEMENT_SEEN="$ANNOUNCEMENT_NUMBER"
    fi
done < "$ANNOUNCEMENT_FILE"

# Save the last announcement number seen by the user
echo "$NEW_LAST_ANNOUNCEMENT_SEEN" > "$USER_ANNOUNCEMENT_FILE"
