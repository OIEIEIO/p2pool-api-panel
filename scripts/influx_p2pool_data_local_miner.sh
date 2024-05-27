#!/bin/bash

# Define InfluxDB Write URL
INFLUXDB_WRITE_URL="http://localhost:8086/write?db=MoneroMetrics"
# InfluxDB authentication credentials
USER="monero"
PASSWORD="1234"

# Define the path to the data directory and cache file
DATA_DIR="/home/jorge/p2pool/build/data/local"
CACHE_FILE="$DATA_DIR/last_miner_cache.txt"

# Define the miner file name
MINER_FILE="miner"

while true; do
    # Navigate to the data directory
    cd "$DATA_DIR"

    # Check if the miner file exists
    if [ ! -f "$MINER_FILE" ]; then
        echo "Miner file not found."
        sleep 21
        continue
    fi

    # Read data from miner file
    current_data=$(cat "$MINER_FILE")

    # Read the last cached data
    last_data=""
    if [ -f "$CACHE_FILE" ]; then
        last_data=$(<$CACHE_FILE)
    fi

    # Compare current data to last data
    if [ "$current_data" == "$last_data" ]; then
        echo "No change in miner data, not writing to InfluxDB."
    else
        # Parse and format miner data for InfluxDB
        miner_data=$(echo "$current_data" | jq -r '
            "miner_data " +
            "current_hashrate=" + (.current_hashrate|tostring) + "," +
            "total_hashes=" + (.total_hashes|tostring) + "," +
            "time_running=" + (.time_running|tostring) + "," +
            "shares_found=" + (.shares_found|tostring) + "," +
            "shares_failed=" + (.shares_failed|tostring) + "," +
            "block_reward_share_percent=" + (.block_reward_share_percent|tostring) + "," +
            "threads=" + (.threads|tostring)
        ')

        # Debug: output the formatted data
        echo "Debug - Formatted data to write:"
        echo "$miner_data"
        echo ""

        # Post data to InfluxDB
        response=$(curl --silent -o response.txt -w "%{http_code}" -X POST -u "$USER:$PASSWORD" "$INFLUXDB_WRITE_URL" --data-binary "$miner_data")

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
    fi

    # Sleep for 21 seconds before the next check
    sleep 21
done
