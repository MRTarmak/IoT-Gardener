#!/usr/bin/env bash

source .env

check_env() {
    if [ -z "$1" ]; then
        echo "ERROR: $2 is not specified."
        echo "Please import or specify in .env file"
        exit 1
    else
        echo "Found: $2"
    fi
} 

check_env "$PORT" "PORT"

BAUDRATE=74880

RETRY=1

while (( $RETRY > 0));
do 
    if [ -e $PORT ]; then
        RETRY=0
        echo ""
        echo "=== Serial Monitor ($PORT @ $BAUDRATE baud) ==="
        echo "Press Ctrl+C to exit."
        arduino-cli monitor -p "$PORT" --config baudrate="$BAUDRATE"
    else
        sleep .1
    fi 
done

