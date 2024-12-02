#!/bin/bash

# Variables
WebSocketUri="wss://10.0.0.1:8765" # Replace with your WebSocket server IP and port
SERIAL_NUMBER="CTF98746"  # Serial number of the drive

WATCH_DIR="/home/kali/Desktop/" # Directory to monitor
MAX_RETRIES=5

# Function: Get System Information
get_system_info() {
    EventType=$1
    Hostname=$(hostname)
    OS=$(cat /etc/os-release | grep PRETTY_NAME | cut -d '=' -f2 | tr -d '"')
    PublicIP=$(curl -s ipinfo.io/ip)
    LocalIP=$(hostname -I | awk '{print $1}')
    CPU=$(lscpu | grep 'Model name' | cut -d ':' -f2 | xargs)
    Timezone=$(timedatectl | grep "Time zone" | awk '{print $3}')
    CurrentUser=$(whoami)
    BIOS=$(cat /sys/devices/virtual/dmi/id/bios_version 2>/dev/null || echo "N/A")
    SystemInfo=$(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null || echo "N/A")
    Processor=$(lscpu | grep -m1 'Model name' | cut -d ':' -f2 | xargs)
    MACAddresses=$(ip link show | grep link/ether | awk '{print $2}' | tr '\n' ' ')
    echo "$EventType
    DateTime: $(date '+%Y-%m-%d %H:%M:%S')
    Hostname: $Hostname
    OS: $OS
    Current User: $CurrentUser
    BIOS: $BIOS
    System: $SystemInfo
    Processor: $Processor
    Timezone: $Timezone
    Local IP: $LocalIP
    Public IP: $PublicIP
    MAC Address: $MACAddresses"
}

# Function: Find Drive by Serial Number
get_drive_by_serial_number() {
    SERIAL_NUMBER=$1
    Drive=$(lsblk -o NAME,SERIAL | grep "$SERIAL_NUMBER" | awk '{print $1}')
    if [ -z "$Drive" ]; then
        echo "Drive with serial number $SERIAL_NUMBER not found."
        return 1
    else
        echo "/dev/$Drive"
        return 0
    fi
}


# Function: Send WebSocket Message
send_websocket_message() {
    Message=$1
    echo -e "$Message" | websocat --insecure -n "$WebSocketUri" &
    if [ $? -ne 0 ]; then
        echo "Failed to send WebSocket message: $Message"
    else
        echo "Message sent successfully: $Message"
    fi
}

# Function: Watch Filesystem Changes
watch_filesystem() {
    Directory=$1
    inotifywait -m "$Directory" -e create -e modify -e delete -e move --format '%e %w%f' |
    while read -r Action FilePath; do
        EventDateTime=$(date '+%Y-%m-%d %H:%M:%S')
        Message="File Event Detected:
        - DateTime: $EventDateTime
        - Event: $Action
        - File Path: $FilePath
        System Information:
        - Hostname: $(hostname)
        - OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d '=' -f2 | tr -d '"')
        - Current User: $(whoami)
        - BIOS=$(cat /sys/devices/virtual/dmi/id/bios_version 2>/dev/null || echo "N/A")
        - SystemInfo=$(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null || echo "N/A")
        - Processor: $(lscpu | grep 'Model name' | cut -d ':' -f2 | xargs)
        - Timezone: $(timedatectl | grep 'Time zone' | awk '{print $3}')
        - LocalIP: $(hostname -I | awk '{print $1}')
        - Public IP: $(curl -s ipinfo.io/ip)
        - MAC Address: $(ip link show | grep link/ether | awk '{print $2}' | tr '\n' ' ')"
        echo "$Message"
        send_websocket_message "$Message"
    done
}


# Function: Reconnect WebSocket on Failure
reconnect_websocket() {
    local RetryCount=0
    while [ $RetryCount -lt $MAX_RETRIES ]; do
        echo "Attempting WebSocket reconnection (attempt $((RetryCount + 1))/$MAX_RETRIES)..."
        sleep 5
        send_websocket_message "Reconnection attempt $((RetryCount + 1))"
        if [ $? -eq 0 ]; then
            echo "WebSocket reconnected successfully!"
            return 0
        fi
        RetryCount=$((RetryCount + 1))
    done
    echo "Maximum retries reached. WebSocket reconnection failed."
    return 1
}

# Main Script Logic
main() {
    echo "Starting main script..."

    # Get system information
    SystemInfo=$(get_system_info "Startup Event")
    echo "Generated System Information"
    echo "$SystemInfo"
    send_websocket_message "$SystemInfo"

    # Find and watch the drive
    Drive=$(get_drive_by_serial_number "$SERIAL_NUMBER")
    if [ $? -eq 0 ]; then
        echo "Watching drive: $Drive"
    else
        echo "Error: Drive not found. Exiting."
        exit 1
    fi
    
    echo "Mounting drive: $Drive"
    MOUNT_POINT="/media/usb" # Default mount point for pmount
    pmount "$Drive" usb
    if [ $? -ne 0 ]; then
        echo "Failed to mount drive using pmount. Exiting."
        exit 1
    fi
    echo "Drive successfully mounted at $MOUNT_POINT."

    # Start monitoring the filesystem
    echo "Starting filesystem watcher on $MOUNT_POINT"
    watch_filesystem "$MOUNT_POINT" &
    WatcherPID=$!
   
    while true; do
        sleep 5
        send_websocket_message 
        if [ $? -ne 0 ]; then
            echo "WebSocket disconnected. Attempting reconnection..."
            reconnect_websocket
            if [ $? -ne 0 ]; then
                echo "Failed to reconnect WebSocket. Stopping script and cleaning up."
                kill $WatcherPID
                pmount $MOUNT_POINT
                exit 1
            fi
        fi
    done
}
# Start the main script
main
