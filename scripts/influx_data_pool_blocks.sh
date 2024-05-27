#!/bin/bash

# Define InfluxDB Write URL
INFLUXDB_WRITE_URL="http://localhost:8086/write?db=MoneroMetrics"
# InfluxDB authentication credentials
USER="monero"
PASSWORD="1234"

# Define the path to the data directory and cache file
DATA_DIR="/home/jorge/p2pool/build/data/pool"
CACHE_FILE="$DATA_DIR/last_blocks_cache.txt"

# Define the block file name
BLOCKS_FILE="blocks"

while true; do
    # Navigate to the data directory
    cd "$DATA_DIR"

    # Check if the blocks file exists
    if [ ! -f "$BLOCKS_FILE" ]; then
        echo "Blocks file not found."
        sleep 21
        continue
    fi

    # Read data from blocks file
    current_data=$(cat "$BLOCKS_FILE")

    # Read the last cached data
    last_data=""
    if [ -f "$CACHE_FILE" ]; then
        last_data=$(<$CACHE_FILE)
    fi

    # Compare current data to last data
    if [ "$current_data" == "$last_data" ]; then
        echo "No change in block data, not writing to InfluxDB."
    else
        # Parse and format block data for InfluxDB
        block_data=$(echo "$current_data" | jq -r '.[] |
            "block_info height=\(.height),hash=\"\(.hash)\",difficulty=\(.difficulty),total_hashes=\(.totalHashes),timestamp=\(.ts)"')

        # Debug: output the formatted data
        echo "Debug - Formatted data to write:"
        echo "$block_data"
        echo ""

        # Post each block's data to InfluxDB
        while read -r line; do
            response=$(curl --silent -o response.txt -w "%{http_code}" -X POST -u "$USER:$PASSWORD" "$INFLUXDB_WRITE_URL" --data-binary "$line")

            # Check if the POST was successful
            if [ "$response" -ne 204 ]; then
                echo "Failed to write data to InfluxDB. HTTP status: $response"
                echo "Response details:"
                cat response.txt
            else
                echo "Data successfully written to InfluxDB."
                # Update the cache file with current data
                echo "$current_data" > "$CACHE_FILE"
            fi
        done <<< "$block_data"
    fi

    # Sleep for 21 seconds before the next check
    sleep 21
done
