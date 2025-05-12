#!/bin/bash

# Configuration
TEST_FILE_URL="https://download.blender.org/demo/movies/BBB/bbb_sunflower_2160p_60fps_normal.mp4.zip"
LOCAL_TEMP_FILE="/tmp/bbb_testfile.zip"
UPLOAD_PATH="benchmark_test/bbb_testfile.zip"  # Will upload to this path in each remote

# Download test file if not already present
if [ ! -f "$LOCAL_TEMP_FILE" ]; then
    echo "Downloading test file..."
    wget "$TEST_FILE_URL" -O "$LOCAL_TEMP_FILE"
    if [ $? -ne 0 ]; then
        echo "Error downloading test file!" >&2
        exit 1
    fi
else
    echo "Using existing test file at $LOCAL_TEMP_FILE"
fi

# Get file size for reference
file_size=$(du -h "$LOCAL_TEMP_FILE" | cut -f1)
echo -e "\nTest file size: $file_size"

# Get list of remotes
echo -e "\nListing all rclone remotes..."
remotes=$(rclone listremotes)

if [ -z "$remotes" ]; then
    echo "No rclone remotes found!" >&2
    exit 1
fi

# Benchmark function
benchmark_remote() {
    local remote=$1
    echo -e "\n\033[1m=== Benchmarking $remote ===\033[0m"
    
    # Create benchmark directory (ignore errors if it exists)
    rclone mkdir "$remote"benchmark_test 2>/dev/null
    
    # Time the upload
    echo "Starting upload test..."
    start_time=$(date +%s)
    rclone copy -P "$LOCAL_TEMP_FILE" "$remote$UPLOAD_PATH"
    upload_exit=$?
    end_time=$(date +%s)
    
    # Calculate results
    duration=$((end_time - start_time))
    if [ $upload_exit -eq 0 ]; then
        echo -e "\n\033[32mUpload successful to $remote\033[0m"
        echo "Time taken: $duration seconds"
        
        # Clean up - delete the test file
        echo "Cleaning up..."
        rclone deletefile -P "$remote$UPLOAD_PATH"
    else
        echo -e "\n\033[31mUpload failed to $remote\033[0m" >&2
    fi
    
    return $upload_exit
}

# Benchmark each remote
for remote in $remotes; do
    benchmark_remote "$remote"
    echo "----------------------------------------"
done

echo -e "\nBenchmarking complete for all remotes!"
