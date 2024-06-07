#!/bin/bash

# Define InfluxDB Write URL and credentials
INFLUXDB_WRITE_URL="http://localhost:8086/write?db=MoneroMetrics"
USER="monero"
PASSWORD="1234"

# Define the path to the data directory and cache file
DATA_DIR="/home/jorge/p2pool/build/data/pool"
CACHE_FILE="$DATA_DIR/last_stats_cache.txt"

# Define the stats file name
STATS_FILE="stats"

# Loop to keep the script running
while true; do
    # Navigate to the data directory
    cd "$DATA_DIR"
    if [ $? -ne 0 ]; then
        echo "Failed to change directory to $DATA_DIR."
        exit 1
    fi

    # Check if the stats file exists
    if [ ! -f "$STATS_FILE" ]; then
        echo "Stats file not found."
        sleep 21
        continue
    fi

    # Read data from stats file
    current_data=$(cat "$STATS_FILE")

    # Read the last cached data
    last_data=""
    if [ -f "$CACHE_FILE" ]; then
        last_data=$(<$CACHE_FILE)
    fi

    # Compare current data to last data
    if [ "$current_data" == "$last_data" ]; then
        echo "No change in pool stats data, not writing to InfluxDB."
    else
        # Parse and format pool stats data for InfluxDB
        stats_data=$(echo "$current_data" | jq -r '
            "pool_stats " +
            "hashRate=" + (.pool_statistics.hashRate // 0|tostring) + "," +
            "miners=" + (.pool_statistics.miners // 0|tostring) + "," +
            "totalHashes=" + (.pool_statistics.totalHashes // 0|tostring) + "," +
            "lastBlockFoundTime=" + (.pool_statistics.lastBlockFoundTime // 0|tostring) + "," +
            "lastBlockFound=" + (.pool_statistics.lastBlockFound // 0|tostring) + "," +
            "totalBlocksFound=" + (.pool_statistics.totalBlocksFound // 0|tostring) + "," +
            "pplnsWeight=" + (.pool_statistics.pplnsWeight // 0|tostring) + "," +
            "pplnsWindowSize=" + (.pool_statistics.pplnsWindowSize // 0|tostring) + "," +
            "sidechainDifficulty=" + (.pool_statistics.sidechainDifficulty // 0|tostring) + "," +
            "sidechainHeight=" + (.pool_statistics.sidechainHeight // 0|tostring)
        ')

        # Debug: output the formatted data
        echo "Debug - Formatted data to write:"
        echo "$stats_data"
        echo ""

        # Post data to InfluxDB
        response=$(curl --silent -o response.txt -w "%{http_code}" -X POST -u "$USER:$PASSWORD" "$INFLUXDB_WRITE_URL" --data-binary "$stats_data")

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
