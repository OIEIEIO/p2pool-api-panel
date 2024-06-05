#!/bin/bash

# Define InfluxDB Write URL and credentials
INFLUXDB_WRITE_URL="http://localhost:8086/write?db=MoneroMetrics"
USER="monero"
PASSWORD="1234"

# Define the path to the data directory and cache file
DATA_DIR="/home/jorge/p2pool/build/data/network"
CACHE_FILE="$DATA_DIR/last_stats_cache.txt"

# Navigate to the data directory
cd "$DATA_DIR"
if [ $? -ne 0 ]; then
    echo "Failed to change directory to $DATA_DIR."
    exit 1
fi

# Continuously check for updates every 21 seconds
while true; do
    # Read data from stats file
    if [ ! -f "stats" ]; then
        echo "Stats file not found."
        sleep 21
        continue
    fi
    current_data=$(<stats)

    # Read the last cached data
    last_data=""
    if [ -f "$CACHE_FILE" ]; then
        last_data=$(<$CACHE_FILE)
    fi

    # Compare current data to last data
    if [ "$current_data" == "$last_data" ]; then
        echo "No change in data, not writing to InfluxDB."
    else
        # Parse and format current data for InfluxDB
        formatted_data=$(echo "$current_data" | jq -r '
            "network_stats " +
            "difficulty=" + (.difficulty|tostring) + "," +
            "hash=\"\(.hash)\"," +
            "height=" + (.height|tostring) + "," +
            "reward=" + (.reward|tostring) + "," +
            "timestamp=" + (.timestamp|tostring)
        ')

        # Debug: output the formatted data
        echo "Debug - Formatted data to write:"
        echo "$formatted_data"
        echo ""

        # Write data to InfluxDB
        response=$(curl --silent -o response.txt -w "%{http_code}" -u "$USER:$PASSWORD" "$INFLUXDB_WRITE_URL" --data-binary "$formatted_data")

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

    # Wait for 21 seconds before the next check
    sleep 21
done