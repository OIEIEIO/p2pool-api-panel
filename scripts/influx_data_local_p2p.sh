#!/bin/bash

# Define InfluxDB Write URL and credentials
INFLUXDB_WRITE_URL="http://localhost:8086/write?db=MoneroMetrics"
USER="monero"
PASSWORD="1234"

# Define the path to the data directory and cache file
DATA_DIR="/home/jorge/p2pool/build/data/local"
CACHE_FILE="$DATA_DIR/last_p2p_cache.txt"

# Define the p2p file name
P2P_FILE="p2p"

# Loop to keep the script running
while true; do
    # Navigate to the data directory
    cd "$DATA_DIR"
    if [ $? -ne 0 ]; then
        echo "Failed to change directory to $DATA_DIR."
        exit 1
    fi

    # Check if the p2p file exists
    if [ ! -f "$P2P_FILE" ]; then
        echo "P2P file not found."
        sleep 21
        continue
    fi

    # Read data from p2p file
    current_data=$(cat "$P2P_FILE")

    # Read the last cached data
    last_data=""
    if [ -f "$CACHE_FILE" ]; then
        last_data=$(<$CACHE_FILE)
    fi

    # Compare current data to last data
    if [ "$current_data" == "$last_data" ]; then
        echo "No change in P2P data, not writing to InfluxDB."
    else
        # Parse and format P2P data for InfluxDB
        p2p_data=$(echo "$current_data" | jq -r '
            "p2p_info " +
            "connections=" + (.connections // 0|tostring) + "," +
            "incoming_connections=" + (.incoming_connections // 0|tostring) + "," +
            "peer_list_size=" + (.peer_list_size // 0|tostring)
        ')

        # Debug: output the formatted data
        echo "Debug - Formatted data to write:"
        echo "$p2p_data"
        echo ""

        # Post data to InfluxDB
        response=$(curl --silent -o response.txt -w "%{http_code}" -X POST -u "$USER:$PASSWORD" "$INFLUXDB_WRITE_URL" --data-binary "$p2p_data")

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
