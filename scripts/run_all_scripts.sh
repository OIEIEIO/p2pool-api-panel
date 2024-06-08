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
