#!/bin/bash

# Set the source backup folder
BACKUP_DIR="/tmp/backup"

# Loop through each backup file
for backup_file in "$BACKUP_DIR"/*.tar.gz; do
    # Extract the username from the backup filename
    filename=$(basename "$backup_file")
    username=$(echo "$filename" | cut -d'_' -f1)
    # Set the destination path for the user's home directory
    user_home="/home/$username"
    # Log the restoration process
    echo "Restoring home directory for user: $username from $backup_file"
    # Create the home directory if it doesn't exist
    mkdir -p "$user_home"
    # Extract the backup tar.gz into the user's home directory
    tar -xzpf "$backup_file" -C "$user_home"
    # Log success
    echo "Restoration complete for $username"
done

# Log the end of the restoration process
echo "All home directories have been restored from $BACKUP_DIR"
