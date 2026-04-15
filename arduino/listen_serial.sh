#! /usr/bin/bash 

PORT=$1

# Check that arduino-cli is installed
if ! command -v arduino-cli &> /dev/null; then
    echo "ERROR: arduino-cli is required."
    exit 1
fi

BAUDRATE=115200
echo""
read -p "Open Serial Monitor on $PORT? (y/N): " OPEN_MONITOR
if [[ "$OPEN_MONITOR" =~ ^[Yy]$ ]]; then
    echo ""
    echo "=== Serial Monitor ($PORT @ $BAUDRATE baud) ==="
    echo "Press Ctrl+C to exit."
    arduino-cli monitor -p "$PORT" --config baudrate="$BAUDRATE"
fi