#!/bin/bash

# Find the active UDP port's hex code in range 27960-27970
# awk extracts the hex code, and the shell converts it to decimal. This is more robust.
hex_port=$(cat /proc/net/udp | awk '$2 ~ /:6D3[8-9A-F]|:6D4[0-2]/ {split($2,a,":"); print a[2]; exit}')

if [ -z "$hex_port" ]; then
    echo "No active UDP port found in range 27960-27970. Exiting."
    exit 1
fi

# Convert hex port to decimal using the shell
active_port=$((16#$hex_port))

echo "Found active port: $active_port"

# Execute quakestat command with the found port and retrieve XML output
xml_output=$(quakestat -xml -rws localhost:$active_port)

# Extract numplayers count from XML output
player_count=$(echo "$xml_output" | grep -oP '<numplayers>\K\d+')

# Check if player count was retrieved successfully
if [ -z "$player_count" ]; then
    echo "Failed to retrieve player count. Exiting."
    exit 1
fi

# Check if player count is less than or equal to 9
if [ "$player_count" -le 9 ]; then
    echo "9 or fewer players are active. Proceeding with update."
    # Issue the RCON command to quit the server using the found port
    timeout 5 icecon "localhost:$active_port" "${RCONPASSWORD}" -c "quit"
    exit_code=$?

    if [ $exit_code -eq 0 ]; then
        echo "RCON command issued successfully."
        exit 0
    else
        echo "Failed to issue RCON command. Exiting."
        exit 1
    fi
else
    echo "More than 9 players active ($player_count players). Exiting without update."
    exit 1
fi