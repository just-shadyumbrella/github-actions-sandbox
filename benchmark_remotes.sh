#!/bin/bash

# Benchmark script for testing rclone upload performance to various cloud remotes
# This script will download a test file and upload it to each configured remote

set -e  # Exit on error

# Create directory for benchmark results
mkdir -p ./benchmark_results

# Color output for better readability
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo "=== Starting Cloud Remotes Benchmark ==="

# Get list of configured remotes
REMOTES=$(rclone listremotes)
if [ -z "$REMOTES" ]; then
    echo -e "${RED}No remotes configured in rclone. Please check your configuration.${NC}"
    exit 1
fi

# Download test file if it doesn't exist
TEST_FILE="bbb_sunflower_2160p_60fps_normal.mp4.zip"
if [ ! -f "$TEST_FILE" ]; then
    echo -e "${YELLOW}Downloading test file: $TEST_FILE${NC}"
    curl -L -o "$TEST_FILE" "https://download.blender.org/demo/movies/BBB/bbb_sunflower_2160p_60fps_normal.mp4.zip"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to download test file!${NC}"
        exit 1
    fi
fi

# Get file size for calculation of transfer rate
FILE_SIZE=$(du -b "$TEST_FILE" | cut -f1)
FILE_SIZE_MB=$(echo "scale=2; $FILE_SIZE/1048576" | bc)
echo -e "Test file size: ${YELLOW}${FILE_SIZE_MB} MB${NC}"

# Run benchmark for each remote
echo "=== Running upload benchmark for each remote ==="

for REMOTE in $REMOTES; do
    REMOTE_NAME="${REMOTE%:}"
    LOG_FILE="./benchmark_results/${REMOTE_NAME}_benchmark.log"
    RESULT_FILE="./benchmark_results/${REMOTE_NAME}_result.txt"
    
    echo -e "\nTesting remote: ${YELLOW}$REMOTE_NAME${NC}"
    echo "Remote: $REMOTE_NAME" > "$RESULT_FILE"
    
    # Try to create a test directory for the benchmark
    echo "Creating test directory..."
    if ! rclone mkdir "${REMOTE}benchmark_test"; then
        echo -e "${RED}Failed to create directory in remote $REMOTE_NAME. Skipping.${NC}"
        echo "Status: FAILED - Could not create directory" >> "$RESULT_FILE"
        continue
    fi
    
    # Start timer
    START_TIME=$(date +%s.%N)
    
    # Upload test file to remote
    echo "Uploading test file..."
    if rclone copy "$TEST_FILE" "${REMOTE}benchmark_test/" --progress 2>&1 | tee "$LOG_FILE"; then
        # End timer and calculate duration
        END_TIME=$(date +%s.%N)
        DURATION=$(echo "$END_TIME - $START_TIME" | bc)
        DURATION_FORMATTED=$(printf "%.2f" $DURATION)
        
        # Calculate upload speed in MB/s
        SPEED=$(echo "scale=2; $FILE_SIZE_MB / $DURATION" | bc)
        
        echo -e "${GREEN}Upload to $REMOTE_NAME completed successfully!${NC}"
        echo -e "Time taken: ${YELLOW}${DURATION_FORMATTED} seconds${NC}"
        echo -e "Upload speed: ${YELLOW}${SPEED} MB/s${NC}"
        
        # Save results
        echo "Status: SUCCESS" >> "$RESULT_FILE"
        echo "Upload Time: $DURATION_FORMATTED seconds" >> "$RESULT_FILE"
        echo "Upload Speed: $SPEED MB/s" >> "$RESULT_FILE"
    else
        echo -e "${RED}Upload to $REMOTE_NAME failed!${NC}"
        echo "Status: FAILED - Upload error" >> "$RESULT_FILE"
    fi
done

echo
echo -e "=== Benchmark completed! Results saved in ./benchmark_results/ ==="
