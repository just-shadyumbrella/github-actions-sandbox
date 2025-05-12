#!/bin/bash

# Configuration
TEST_FILE_URL="https://download.blender.org/demo/movies/BBB/bbb_sunflower_2160p_60fps_normal.mp4.zip"
LOCAL_TEMP_FILE="/tmp/bbb_testfile.zip"
UPLOAD_PATH="benchmark_test/bbb_testfile.zip"
LOG_FILE="/tmp/rclone_benchmark_$(date +%Y%m%d_%H%M%S).log"

# Initialize results arrays
declare -A results     # remote -> time
declare -A statuses    # remote -> status
declare -A speeds      # remote -> speed in MB/s
declare -A sizes       # remote -> actual uploaded size

# Check and install screenfetch if needed
check_dependencies() {
    if ! command -v screenfetch &> /dev/null; then
        echo "Installing screenfetch..."
        if command -v apt-get &> /dev/null; then
            sudo apt-get install -y screenfetch
        elif command -v yum &> /dev/null; then
            sudo yum install -y screenfetch
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y screenfetch
        elif command -v pacman &> /dev/null; then
            sudo pacman -Sy --noconfirm screenfetch
        else
            echo "Could not install screenfetch automatically. Please install it manually."
        fi
    fi
}

# Get system info
get_system_info() {
    echo -e "\n\033[1m=== System Information ===\033[0m"
    if command -v screenfetch &> /dev/null; then
        screenfetch -v
    else
        echo "screenfetch not available. Using basic system info:"
        uname -a
        lsb_release -a 2>/dev/null || cat /etc/*release 2>/dev/null
    fi
}

# Download test file if not already present
download_test_file() {
    if [ ! -f "$LOCAL_TEMP_FILE" ]; then
        echo "Downloading test file..."
        wget "$TEST_FILE_URL" -O "$LOCAL_TEMP_FILE" || {
            echo "Error downloading test file!" >&2
            exit 1
        }
    else
        echo "Using existing test file at $LOCAL_TEMP_FILE"
    fi
    
    # Get file size for reference
    file_size=$(du -h "$LOCAL_TEMP_FILE" | cut -f1)
    file_size_bytes=$(stat -c%s "$LOCAL_TEMP_FILE")
    echo -e "\nTest file size: $file_size ($file_size_bytes bytes)"
}

# Benchmark function
benchmark_remote() {
    local remote=$1
    echo -e "\n\033[1m=== Benchmarking $remote ===\033[0m"
    
    # Create benchmark directory
    rclone mkdir "${remote}benchmark_test" 2>/dev/null
    
    # Time the upload
    echo "Starting upload test..."
    start_time=$(date +%s.%N)
    rclone copy -P "$LOCAL_TEMP_FILE" "${remote}${UPLOAD_PATH}"
    upload_exit=$?
    end_time=$(date +%s.%N)
    
    # Calculate results
    duration=$(echo "$end_time - $start_time" | bc)
    if [ $upload_exit -eq 0 ]; then
        # Get actual uploaded size (in case compression happened)
        uploaded_size=$(rclone size "${remote}${UPLOAD_PATH}" --json | jq '.bytes')
        speed=$(echo "scale=2; $uploaded_size / $duration / 1024 / 1024" | bc)
        
        echo -e "\n\033[32mUpload successful to $remote\033[0m"
        echo "Time taken: $duration seconds"
        echo "Upload speed: $speed MB/s"
        
        results["$remote"]=$duration
        speeds["$remote"]=$speed
        sizes["$remote"]=$uploaded_size
        statuses["$remote"]="SUCCESS"
        
        # Clean up
        echo "Cleaning up..."
        rclone deletefile "${remote}${UPLOAD_PATH}"
    else
        echo -e "\n\033[31mUpload failed to $remote\033[0m" >&2
        statuses["$remote"]="FAILED"
    fi
    
    # Log to file
    {
        echo "=== $remote ==="
        echo "Status: ${statuses[$remote]}"
        echo "Time: $duration seconds"
        [ "${statuses[$remote]}" = "SUCCESS" ] && {
            echo "Speed: $speed MB/s"
            echo "Size: $uploaded_size bytes"
        }
        echo ""
    } >> "$LOG_FILE"
}

# Main execution
{
    echo "Rclone Benchmark Test - $(date)"
    echo "Test file: $TEST_FILE_URL"
    echo "Local path: $LOCAL_TEMP_FILE"
    get_system_info >> "$LOG_FILE"
} > "$LOG_FILE"

# Check dependencies
check_dependencies

# Download test file
download_test_file

# Get list of remotes
echo -e "\nListing all rclone remotes..."
remotes=$(rclone listremotes)

if [ -z "$remotes" ]; then
    echo "No rclone remotes found!" >&2
    exit 1
fi

# Benchmark each remote
for remote in $remotes; do
    benchmark_remote "$remote"
    echo "----------------------------------------"
done

# Display summary
echo -e "\n\033[1m=== Benchmark Summary ===\033[0m"
printf "%-20s %-10s %-12s %-12s %-15s\n" "REMOTE" "STATUS" "TIME (sec)" "SPEED (MB/s)" "SIZE (MB)"
printf "%-20s %-10s %-12s %-12s %-15s\n" "------" "------" "---------" "-----------" "---------"

for remote in "${!results[@]}"; do
    size_mb=$(echo "scale=2; ${sizes[$remote]} / 1024 / 1024" | bc)
    printf "%-20s %-10s %-12.2f %-12.2f %-15.2f\n" \
        "$remote" \
        "${statuses[$remote]}" \
        "${results[$remote]}" \
        "${speeds[$remote]}" \
        "$size_mb"
done | sort -k3n  # Sort by upload time

echo -e "\nDetailed log saved to: $LOG_FILE"
echo -e "\nSystem information:\n$(cat "$LOG_FILE" | grep -A 15 "System Information")"
