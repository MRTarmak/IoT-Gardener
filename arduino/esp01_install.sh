#!/usr/bin/env bash

FQBN="esp8266:esp8266:generic:eesz=1M64,baud=115200"
SKETCH_DIR="./src/esp8266"
LIBRARIES_DIR="./libraries"

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

# Check arduino-cli
if ! command -v arduino-cli &> /dev/null; then
    echo "ERROR: arduino-cli is required."
    exit 1
fi

EXTRA_FLAGS="$@"


tz_offset=$(date +%z)
sign=${tz_offset:0:1}
hours=${tz_offset:1:2}
minutes=${tz_offset:3:2}
TZ_OFFSET=$((hours * 3600 + minutes * 60))
[ "$sign" = "-" ] && TZ_OFFSET=$(( -TZ_OFFSET ))


# Check env
check_env "$MQ_ENDPOINT" "MQ_ENDPOINT"
check_env "$MQ_PORT" "MQ_PORT"
check_env "$MQ_USERNAME" "MQ_USERNAME"
check_env "$MQ_PASSWORD" "MQ_PASSWORD"
check_env "$PORT" "PORT"

echo "TZ_OFFSET=$TZ_OFFSET"

#
# Compile
#

COMPILE_CMD=(arduino-cli compile --fqbn "$FQBN" --libraries "$LIBRARIES_DIR")

MACRO_FLAGS="-DMQ_ENDPOINT=$MQ_ENDPOINT "
MACRO_FLAGS+="-DMQ_PORT=$MQ_PORT "
MACRO_FLAGS+="-DMQ_USERNAME=$MQ_USERNAME "
MACRO_FLAGS+="-DMQ_PASSWORD=$MQ_PASSWORD "
MACRO_FLAGS+="-DTZ_OFFSET=$TZ_OFFSET "


COMPILE_CMD+=(--build-property "compiler.cpp.extra_flags=$MACRO_FLAGS")
COMPILE_CMD+=("$SKETCH_DIR")

echo ""
echo "=== COMPILING PROJECT FOR ESP8266 ==="
echo "${COMPILE_CMD[@]}"

"${COMPILE_CMD[@]}"

if [ $? -ne 0 ]; then
    echo "COMPILATION ERROR"
    exit 1
fi

echo "COMPILATION SUCCESS"

#
# Upload
#

echo ""
echo "=== WARNING: MANUALLY SWITCH TO UPLOADING MODE  ==="
echo "1. Make sure that Arduino UNO has RESET -> GND bridge"
echo "2. Disable power supply on Arduino UNO and ESP01"
echo "3. Connect ESP01's GPIO0 pin to GND"
echo "4. Enable power supply"
echo "5. Connect ESP01's GPIO0 pin to 3.3V via 220 Ohm pull-up resistor"
read -p "Press ENTER to contiue with uploading..."

echo ""
echo "=== UPLOADING TO $PORT === "

arduino-cli upload -p "$PORT" --fqbn "$FQBN" "$SKETCH_DIR" 2>errors.txt

RET=$?
if [ $RET -ne 0 ]; then
    echo "UPLOADING ERROR $RET"
    exit 1
fi

if [ -s errors.txt ]; then
    echo "Program failed with errors:"
    cat errors.txt
    echo ""
    rm -f errors.txt
    exit 1
fi

rm -f errors.txt
echo "UPLOADING SUCCESS"

./serial_monitor