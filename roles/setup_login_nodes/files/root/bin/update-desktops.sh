#!/bin/bash
# Deploy .desktop files from /usr/local/share to all users (existing + new)
# and ensure /etc/skel/Desktop has them for new users

SOURCE_DIR="/usr/local/share"
SKEL_DIR="/etc/skel/Desktop"

# Ensure skel Desktop exists
sudo mkdir -p "$SKEL_DIR"

# Loop through all .desktop files in SOURCE_DIR
for desktop_file in "$SOURCE_DIR"/*.desktop; do
    basefile=$(basename "$desktop_file")

    # --- 1️⃣ Ensure /etc/skel/Desktop has symlink ---
    target_skel="$SKEL_DIR/$basefile"
    if [ -e "$target_skel" ] || [ -L "$target_skel" ]; then
        sudo rm -f "$target_skel"
    fi
    sudo ln -s "$desktop_file" "$target_skel"
    echo "Updated skel symlink: $basefile"

    # --- 2️⃣ Ensure all existing users have symlink in ~/Desktop ---
    for homedir in /home/*; do
        user=$(basename "$homedir")
        user_desktop="$homedir/Desktop"

        # Skip if Desktop does not exist
        [ -d "$user_desktop" ] || continue

        target_user="$user_desktop/$basefile"
        if [ -e "$target_user" ] || [ -L "$target_user" ]; then
            sudo rm -f "$target_user"
        fi
        sudo ln -s "$desktop_file" "$target_user"
        sudo chown -h "$user" "$target_user"
        echo "Updated symlink for user $user: $basefile"
    done
done

echo "Deployment complete for all users and skel."
