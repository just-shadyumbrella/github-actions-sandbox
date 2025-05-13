#!/bin/bash

# Color output for better readability
BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Results formatting script for rclone benchmarks
# This script processes benchmark results and displays them in a formatted table

echo -e "${BOLD}=== Cloud Remotes Benchmark Results ===${NC}"
echo

# Create header for the results table
printf "%-20s | %-10s | %-20s | %-15s\n" "Remote" "Status" "Upload Time" "Upload Speed"
printf "%-20s-+-%-10s-+-%-20s-+-%-15s\n" "--------------------" "----------" "--------------------" "---------------"

# Process each result file
for RESULT_FILE in ./benchmark_results/*_result.txt; do
    if [ -f "$RESULT_FILE" ]; then
        # Extract remote name from filename
        FILENAME=$(basename "$RESULT_FILE")
        REMOTE_NAME="${FILENAME%_result.txt}"
        
        # Extract data from result file
        STATUS=$(grep "Status:" "$RESULT_FILE" | cut -d ":" -f2- | xargs)
        UPLOAD_TIME=$(grep "Upload Time:" "$RESULT_FILE" | cut -d ":" -f2- | xargs)
        UPLOAD_SPEED=$(grep "Upload Speed:" "$RESULT_FILE" | cut -d ":" -f2- | xargs)
        
        # Set default values if not found
        UPLOAD_TIME=${UPLOAD_TIME:-"N/A"}
        UPLOAD_SPEED=${UPLOAD_SPEED:-"N/A"}
        
        # Apply colors based on status
        if [[ "$STATUS" == SUCCESS* ]]; then
            STATUS_COLORED="\033[0;32m$STATUS\033[0m"  # Green for success
        else
            STATUS_COLORED="\033[0;31m$STATUS\033[0m"  # Red for failure
        fi
        
        # Print formatted result with color
        printf "%-20s | $STATUS_COLORED%-10s\033[0m | %-20s | %-15s\n" "$REMOTE_NAME" "" "$UPLOAD_TIME" "$UPLOAD_SPEED"
    fi
done

echo
echo -e "${BOLD}=== End of Benchmark Results ===${NC}"

# Create a GitHub Actions output summary for better visibility in the Actions UI
if [ -n "$GITHUB_STEP_SUMMARY" ]; then
    {
        echo "## Cloud Remotes Benchmark Results"
        echo
        echo "| Remote | Status | Upload Time | Upload Speed |"
        echo "| ------ | ------ | ----------- | ----------- |"
        
        for RESULT_FILE in ./benchmark_results/*_result.txt; do
            if [ -f "$RESULT_FILE" ]; then
                FILENAME=$(basename "$RESULT_FILE")
                REMOTE_NAME="${FILENAME%_result.txt}"
                
                STATUS=$(grep "Status:" "$RESULT_FILE" | cut -d ":" -f2- | xargs)
                UPLOAD_TIME=$(grep "Upload Time:" "$RESULT_FILE" | cut -d ":" -f2- | xargs)
                UPLOAD_SPEED=$(grep "Upload Speed:" "$RESULT_FILE" | cut -d ":" -f2- | xargs)
                
                UPLOAD_TIME=${UPLOAD_TIME:-"N/A"}
                UPLOAD_SPEED=${UPLOAD_SPEED:-"N/A"}
                
                echo "| $REMOTE_NAME | $STATUS | $UPLOAD_TIME | $UPLOAD_SPEED |"
            fi
        done
    } >> "$GITHUB_STEP_SUMMARY"
fi
