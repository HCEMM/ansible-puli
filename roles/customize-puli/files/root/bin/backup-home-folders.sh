#!/bin/bash

# Set the backup destination folder
BACKUP_DIR="/scratch/jsequeira/home"

# Ensure the backup directory exists
mkdir -p "$BACKUP_DIR"

# Loop through each user home directory in /home
for user_home in /home/*; do
    # Ensure we're dealing with a directory
    if [[ -d "$user_home" ]]; then
        # Extract the username from the home directory path
        username=$(basename "$user_home")

        # Create the backup filename with .tar.gz extension
        backup_file="$BACKUP_DIR/${username}_home_backup_$(date +%F).tar.gz"

        # Log the backup process
        echo "Backing up home directory for user: $username to $backup_file"

        # Use tar to compress and back up the home directory
        tar -czpf "$backup_file" -C "$user_home" . --preserve-permissions --ignore-failed-read

        # Log success
        echo "Backup complete for $username"
    fi
done

# Log the end of the backup process
echo "All home directories have been backed up to $BACKUP_DIR"
