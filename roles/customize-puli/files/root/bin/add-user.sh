#!/bin/bash

# Function to print usage
usage() {
    echo "Usage: $0 -u <username> -p <password> -g <group> [-i <USER_ID>] [-d <GROUP_ID>] "
    exit 1
}

# Parse named arguments using getopts
while getopts "u:p:g:i:d:" opt; do
    case "$opt" in
        u) USERNAME=$OPTARG ;;
        p) PASSWORD=$OPTARG ;;
        g) GROUP=$OPTARG ;;
        i) USER_ID=$OPTARG ;;
        d) GROUP_ID=$OPTARG ;;
        *) usage ;;
    esac
done

# Check if mandatory options are provided
if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ] || [ -z "$GROUP" ]; then
    echo "Error: Username, password, and group are mandatory."
    usage
fi

# Set a default USER_ID if not provided
if [ -z "$USER_ID" ]; then
    USER_ID=$(getent passwd | tail -n1 | cut -d: -f3 | awk '{print $1+1}')
fi

# Check if group exists
if getent group "$GROUP" > /dev/null; then
    echo "Group $GROUP found!"
else
    # Create the group only if it does not exist
    if [ -z "$GROUP_ID" ]; then
        echo "Group $GROUP not found. Please provide a GROUP_ID to create the group."
        usage
    else
        groupadd -g "$GROUP_ID" "$GROUP"
    fi
    echo "Group $GROUP created."
fi

# Create a new user with the given username, password, group, and USER_ID
useradd -m -p "$(openssl passwd -1 "$PASSWORD")" -g "$GROUP" -u "$USER_ID" "$USERNAME"
echo "User $USERNAME created with UID=$USER_ID and added to group $GROUP."

# Add the user to the SLURM database
sacctmgr -i add account "$GROUP"
sacctmgr -i add user "$USERNAME" account="$GROUP"

echo "User $USERNAME added to SLURM accounting under account $GROUP."

echo "User has been added, but remember to run 'wwctl overlay build' to propagate the changes to all nodes!!"
echo "Here, to be easier... though it never gets easy, does it?"
echo "wwctl overlay build"
