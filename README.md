# P2Pool API Panel

**Disclaimer: This repository is a Work in Progress (WIP) and is not yet complete or ready for use. However, the information provided may be useful for those who wish to modify, finish, and use it. The setup has been tested for about 30 days, but some features are still being sorted out, and learning about Grafana and InfluxDB is ongoing.**

This repository contains a mining proxy panel for monitoring P2Pool mining activities. The panel uses InfluxDB to store pool information fetched from the P2Pool API and Grafana to visualize the data.

## Features

- Fetches data from the P2Pool API.
- Stores data in InfluxDB.
- Visualizes mining metrics using Grafana.
- Custom scripts for data ingestion.

## Prerequisites

- InfluxDB
- Grafana
- jq (for JSON parsing)
- cURL (for HTTP requests)
- P2Pool setup
- VPS (Virtual Private Server) to host the nodes

## VPS Setup

The current setup uses a VPS with the following specifications:
- 8 CPU cores
- 24 GB RAM
- 500 GB NVMe drive
- Ubuntu 22.04 LTS

## Installation

### 1. Clone the Repository

```
git clone https://github.com/OIEIEIO/p2pool-api-panel.git
cd p2pool-api-panel
```

### 2. Set Up P2Pool
Start P2Pool with the appropriate flags to enable data and API:

```
./p2pool --mini --data-api data --local-api --zmq-port 18084 --stratum 0.0.0.0:3333 --p2p 0.0.0.0:37889 --loglevel 0 --rpc-port 18089 --wallet 45678jma
```
Understanding the --data-api Flag
Using the --data-api flag with P2Pool enables the creation of a data directory, along with several subdirectories and files, which are updated every 20 seconds. This is crucial for monitoring and fetching real-time mining data. Here is an overview of the directory structure created:
```
├── local
│   ├── console
│   ├── p2p
│   ├── response.txt
│   └── stratum
├── network
│   ├── last_stats_cache.txt
│   ├── response.txt
│   └── stats
├── pool
│   ├── blocks
│   ├── last_blocks_cache.txt
│   ├── response.txt
│   └── stats
└── stats_mod
```
- local: Contains data related to the local node, including console outputs, peer-to-peer information, and stratum details.
- network: Stores network-wide statistics, including a cache of the last statistics, a response file, and the current stats.
- pool: Holds data specific to the mining pool, such as block information, a cache of the last blocks, a response file, and the current stats.
- stats_mod: This directory is reserved for modified stats or additional statistical data.
### 3. Set Up InfluxDB
Ensure InfluxDB is running and accessible. Install and start InfluxDB if it is not already running.

### 4. Configure and Run the Ingest Scripts
The repository includes several scripts for data ingestion, which run in a loop to continuously check the API, write values to cache, and update InfluxDB when a value changes. The scripts are located in the scripts/ directory.

Separate ingest scripts for each API data point were used, which allows for more flexibility in how data is ingested. This approach lets you manage and update each script independently. However, it is possible to combine these scripts into a single script if desired.

### Example: scripts/influx_stratum_data_loop.sh
```
#!/bin/bash

# Define InfluxDB Write URL
INFLUXDB_WRITE_URL="http://localhost:8086/write?db=MoneroMetrics"
# InfluxDB authentication credentials
USER="monero"
PASSWORD="1234"

# Define the path to the data directory
DATA_DIR="/home/jorge/p2pool/build/data/local"

# Loop to keep the script running
while true
do
    # Navigate to the data directory
    cd "$DATA_DIR"

    # Check if the directory change was successful
    if [ $? -ne 0 ]; then
        echo "Failed to change directory to $DATA_DIR."
        exit 1
    fi

    # Define data file names
    STRATUM_FILE="stratum"

    # Check and read data from stratum file
    if [ ! -f "$STRATUM_FILE" ]; then
        echo "Stratum file not found."
        continue
    fi

    # Parse data from stratum file using jq
    stratum_data=$(cat "$STRATUM_FILE" | jq -r '
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
        continue
    fi

    echo "Data successfully written to InfluxDB."

    # Wait for 21 seconds before running the script again
    sleep 21
done
```
Run the script:

```
bash scripts/influx_stratum_data_loop.sh
```
### 5. Set Up Grafana
Ensure Grafana is running and accessible. Install and start Grafana if it is not already running.

Open Grafana in your browser: http://localhost:3000
Log in with the default credentials (admin / admin).
Add InfluxDB as a data source.
Import the provided Grafana dashboard JSON file from the grafana/ directory.
Using the VPS Setup
To run this setup, you can use a VPS (Virtual Private Server) to host your Monero node and P2Pool node. Set up InfluxDB and Grafana on the VPS as needed. Use screen to manage multiple terminals for running monerod, p2pool, and one ingest script for folder/file output by the API.

Example of Using screen
Start monerod in one screen session:

```
screen -S monerod
./monerod --detach
```
Start p2pool in another screen session:
```
screen -S p2pool
./p2pool --mini --data-api data --local-api --zmq-port 18084 --stratum 0.0.0.0:3333 --p2p 0.0.0.0:37889 --loglevel 0 --rpc-port 18089 --wallet 45678jma
```
Start the ingest script in another screen session:
```
screen -S influx_pool_info
bash scripts/influx_pool_info.sh
```
You can detach from a screen session by pressing Ctrl + A followed by D. To reattach to a session, use:
```
screen -r <session_name>
```
### Screenshots
Here are some screenshots of the P2Pool API Panel in action:

Pool API Panel


![Pool API Panel](screenshots/Screenshot%202024-05-16%20202717.png)
![Another Screenshot](screenshots/Screenshot%202024-05-15%20224046.png)
![Another Screenshot](screenshots/Screenshot%202024-05-15%20214323.png)
### Customization
Modifying the Ingest Scripts
You can customize the ingest scripts to fetch additional data from the P2Pool API or modify the existing data processing logic. The scripts are located in the scripts/ directory.

### Updating Grafana Dashboards
You can create custom dashboards or modify the existing ones in Grafana to suit your monitoring needs. The default dashboard JSON file is located in the grafana/ directory.

### Contributing
Contributions are welcome! Please open an issue or submit a pull request for any improvements or bug fixes.

### License
This project is licensed under the MIT License. See the LICENSE file for details.
