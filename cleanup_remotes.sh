#!/bin/bash

# Color output for better readability
BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Get list of remotes
echo -e "${BOLD}=== List of available rclone remotes: ===${BOLD}"
remotes=$(rclone listremotes)
echo $remotes

# Check if no remotes found
if [ -z "$remotes" ]; then
    echo -e "${RED}No remotes configured in rclone. Please check your configuration.${NC}"
    exit 1
fi

# Loop through each remote
for remote in $remotes; do
    echo
    echo -e "Purging benchmark file from remote \"${YELLOW}${remote}${NC}\""
    rclone purge -P "${remote}benchmark_test/"
    
    # Check the exit status of the command
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Successfully purge ${NC}\"${YELLOW}${remote}\"${NC}"
    else
        echo -e "${RED}Error purge \"$remote\"${NC}" >&2
    fi
done

echo
echo -e "${BOLD}=== All remotes checked! ===${NC}"
