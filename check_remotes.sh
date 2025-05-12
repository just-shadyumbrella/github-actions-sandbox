#!/bin/bash

# Get list of remotes
echo "Listing all rclone remotes..."
remotes=$(rclone listremotes)

# Check if no remotes found
if [ -z "$remotes" ]; then
    echo "No rclone remotes found!"
    exit 1
fi

# Loop through each remote
for remote in $remotes; do
    echo -e "\nChecking remote: $remote"
    
    # Remove the trailing ':' from the remote name
    #clean_remote=${remote%:}
    
    # Check the remote with verbose listing
    echo "Running: rclone ls -v $remote"
    rclone ls -v "$remote"
    
    # Check the exit status of the command
    if [ $? -eq 0 ]; then
        echo "Successfully checked $clean_remote"
    else
        echo "Error checking $clean_remote" >&2
    fi
done

echo -e "\nAll remotes checked!"
