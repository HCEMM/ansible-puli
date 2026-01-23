#!/bin/bash

# Function to print usage
usage() {
    echo "Usage: $0 -u <username>"
    exit 1
}

# Parse input
while getopts "u:" opt; do
    case "$opt" in
        u) USERNAME=$OPTARG ;;
        *) usage ;;
    esac
done

# Check if username is provided
if [ -z "$USERNAME" ]; then
    echo "Error: Username is required."
    usage
fi

# Confirm user exists
if id "$USERNAME" &>/dev/null; then
    echo "User $USERNAME found. Proceeding with removal."
else
    echo "Error: User $USERNAME does not exist."
    exit 1
fi

# Remove user from Slurm accounting
echo "Removing user $USERNAME from Slurm accounting..."
sacctmgr -i delete user name="$USERNAME"

# Delete user and their home directory
echo "Deleting user $USERNAME and their home directory..."
userdel -r "$USERNAME"

if [ $? -eq 0 ]; then
    echo "User $USERNAME successfully removed from system and SLURM."
else
    echo "Error: Failed to delete user $USERNAME."
    exit 1
fi

# Reminder about overlays
echo "Don't forget to rebuild the overlays!"
echo "wwctl overlay build"