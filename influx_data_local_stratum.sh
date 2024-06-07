#!/bin/bash

# Define InfluxDB Write URL and credentials
INFLUXDB_WRITE_URL="http://localhost:8086/write?db=MoneroMetrics"
USER="monero"
PASSWORD="1234"

# Define the path to the data directory and cache file
DATA_DIR="/home/jorge/p2pool/build/data/local"
CACHE_FILE="$DATA_DIR/last_stratum_cache.txt"

# Loop to keep the script running
while true; do
    # Navigate to the data directory
    cd "$DATA_DIR"
    if [ $? -ne 0 ]; then
        echo "Failed to change directory to $DATA_DIR."
        exit 1
    fi

    # Define the stratum file name
    STRATUM_FILE="stratum"

    # Check if the stratum file exists
    if [ ! -f "$STRATUM_FILE" ]; then
        echo "Stratum file not found."
        sleep 21
        continue
    fi

    # Read data from stratum file
    current_data=$(cat "$STRATUM_FILE")

    # Read the last cached data
    last_data=""
    if [ -f "$CACHE_FILE" ]; then
        last_data=$(<$CACHE_FILE)
    fi

    # Compare current data to last data
    if [ "$current_data" == "$last_data" ]; then
        echo "No change in stratum data, not writing to InfluxDB."
    else
        # Parse and format stratum data for InfluxDB
        stratum_data=$(echo "$current_data" | jq -r '
            "stratum_info " +
            "hashrate_15m=" + (.hashrate_15m // 0|tostring) + "," +
            "hashrate_1h=" + (.hashrate_1h // 0|tostring) + "," +
            "hashrate_24h=" + (.hashrate_24h // 0|tostring) + "," +
            "total_hashes=" + (.total_hashes // 0|tostring) + "," +
            "shares_found=" + (.shares_found // 0|tostring) + "," +
            "shares_failed=" + (.shares_failed // 0|tostring) + "," +
            "average_effort=" + (.average_effort // 0|tostring) + "," +
            "current_effort=" + (.current_effort // 0|tostring) + "," +
            "connections=" + (.connections // 0|tostring) + "," +
            "incoming_connections=" + (.incoming_connections // 0|tostring) + "," +
            "block_reward_share_percent=" + (.block_reward_share_percent // 0|tostring)
        ')

        # Debug: output the formatted data
        echo "Debug - Formatted data to write:"
        echo "$stratum_data"
        echo ""

        # Post data to InfluxDB
        response=$(curl --silent -o response.txt -w "%{http_code}" -X POST -u "$USER:$PASSWORD" "$INFLUXDB_WRITE_URL" --data-binary "$stratum_data")

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

    # Wait for 21 seconds before running the script again
    sleep 21
done
