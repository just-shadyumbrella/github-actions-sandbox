#!/bin/bash

# Get list of remotes
echo "List of available rclone remotes:"
remotes=$(rclone listremotes)
echo

# Color output for better readability
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Check if no remotes found
if [ -z "$remotes" ]; then
    echo -e "${RED}No remotes configured in rclone. Please check your configuration.${NC}"
    exit 1
fi

# Loop through each remote
for remote in $remotes; do
    echo
    echo -e "Checking remote \"$remote\""
    rclone tree -aP --level 1 --dirsfirst "$remote"
    
    # Check the exit status of the command
    if [ $? -eq 0 ]; then
        echo "${GREEN}Successfully checked \"$remote\"${NC}"
    else
        echo "${RED}Error checking \"$remote\"${NC}" >&2
    fi
done

echo
echo -e "${YELLOW}All remotes checked!${NC}"
