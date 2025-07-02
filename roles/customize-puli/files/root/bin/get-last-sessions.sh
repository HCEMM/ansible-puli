#!/bin/bash

echo -e "Username\tLast Login"
echo "-----------------------------"

# Loop through users with UID >= 1000
awk -F: '$3 >= 1000 && $3 < 65534 { print $1 }' /etc/passwd | while read -r user; do
    lastlog -u "$user" | awk 'NR==2'
done