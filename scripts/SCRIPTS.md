
# Explanation:

## Initialization and Variables:
Sets up InfluxDB URL, credentials, data directory, and cache file path.

## Infinite Loop:
Continuously checks for new data in the blocks file.

## Data Handling:
Reads the current data from the blocks file. Compares it with the last cached data from last_blocks_cache.txt. If unchanged, it skips writing to InfluxDB. If changed, it formats the data using jq.

## Data Posting:
Uses curl to post formatted data to InfluxDB and captures the response in response.txt.

## Cache Update:
Updates the cache file if data is successfully written to InfluxDB.

## Sleep:
Waits 21 seconds before the next iteration.

## Master Script to Run All Data Scripts:

### Initialization and Variables:
Sets up the logging and cleanup functions to handle script termination and process management.

### Infinite Loop:
Continuously runs all data scripts in sequence with a sleep interval between cycles.

### Script Execution and Logging:
Runs each data script with a timeout. Logs the output indicating whether new data was written or no new data was found.

### Safe Termination:
Handles termination signals to safely stop the script and all running processes.

## Script Details:

```bash
#!/bin/bash

# Function to handle termination signals
cleanup() {
    echo "$(date) - Terminating script and all running processes..." | tee -a script.log
    pkill -P $$
    exit 0
}

# Trap termination signals and call cleanup
trap cleanup SIGINT SIGTERM

while true; do
    echo "$(date) - Starting script execution cycle." | tee -a script.log

    # Run scripts in background
    ./influx_data_local_miner.sh &
    ./influx_data_local_p2p.sh &
    ./influx_data_local_stratum.sh &
    ./influx_data_network_stats.sh &
    ./influx_data_pool_blocks.sh &
    ./influx_data_pool_stats.sh &

    # Wait for all background jobs to finish
    wait

    echo "$(date) - Script execution cycle completed. Sleeping for 21 seconds." | tee -a script.log
    sleep 21
done
```

### How to Use:

1. **Ensure Each Data Script is Correct**: Make sure each of the individual scripts (`influx_data_local_miner.sh`, `influx_data_local_p2p.sh`, etc.) is executable and correctly outputs data.
2. **Create or Update the Master Script**: Save the above script as `run_all_scripts.sh`.
3. **Make the Master Script Executable**: Ensure the script is executable by running:

    ```bash
    chmod +x run_all_scripts.sh
    ```

4. **Run the Master Script**: Start the script:

    ```bash
    ./run_all_scripts.sh
    ```

### Stopping the Script:

To stop the script safely, you can simply press `Ctrl+C`, which will send a `SIGINT` signal to the script, triggering the cleanup process. Alternatively, you can use:

```bash
pkill -f run_all_scripts.sh
```

### How to Use:

1. **Ensure Each Data Script is Correct**: Make sure each of the individual scripts (`influx_data_local_miner.sh`, `influx_data_local_p2p.sh`, etc.) is executable and correctly outputs data.
2. **Create or Update the Master Script**: Save the above script as `run_all_scripts.sh`.
3. **Make the Master Script Executable**: Ensure the script is executable by running:

    ```bash
    chmod +x run_all_scripts.sh
    ```

4. **Run the Master Script**: Start the script:

    ```bash
    ./run_all_scripts.sh
    ```

### Stopping the Script:

To stop the script safely, you can simply press `Ctrl+C`, which will send a `SIGINT` signal to the script, triggering the cleanup process. Alternatively, you can use:

```bash
pkill -f run_all_scripts.sh
```