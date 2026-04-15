#! /usr/bin/bash 

FQBN="arduino:avr:uno"
SKETCH_DIR="./src/gardener"
LIBRARIES_DIR="./libraries"

source .env

check_env() {
    if [ -z "$1" ]; then
        echo "ERROR: $2 is not specified."
        echo "Please import or specify in .env file"
        exit 0
    else
        echo "Found: $2=$1"
    fi
} 

# Check that arduino-cli is installed
if ! command -v arduino-cli &> /dev/null; then
    echo "ERROR: arduino-cli is required."
    exit 1
fi

EXTRA_FLAGS="$@"


check_env "$EMQX_ENDPOINT" "EMQX_ENDPOINT"
check_env "$EMQX_PORT" "EMQX_PORT"
check_env "$EMQX_USERNAME" "EMQX_USERNAME"
check_env "$EMQX_PASSWORD" "EMQX_PASSWORD"

#
# Compile
#

# Base compilation command
COMPILE_CMD=(arduino-cli compile --fqbn "$FQBN" --libraries "$LIBRARIES_DIR")

MACRO_FLAGS="-DMQ_ENDPOINT=$EMQX_ENDPOINT "
MACRO_FLAGS+="-DMQ_PORT=$EMQX_PORT "
MACRO_FLAGS+="-DMQ_USERNAME=$EMQX_USERNAME "
MACRO_FLAGS+="-DMQ_PASSWORD=$EMQX_PASSWORD "

if [ -n "$EXTRA_FLAGS" ]; then
    echo "Using extra flags: $EXTRA_FLAGS"
    MACRO_FLAGS+="$EXTRA_FLAGS"
fi

COMPILE_CMD+=(--build-property "build.extra_flags=$MACRO_FLAGS")


COMPILE_CMD+=("$SKETCH_DIR")

echo ""
echo "=== COMPILING PROJECT ==="
echo "${COMPILE_CMD[@]}"

"${COMPILE_CMD[@]}"

if [ $? -ne 0 ]; then
    echo "COMPILATION ERROR"
    
    exit 1
fi

echo "COMPILATION SUCCESS"

#
# UPLOAD
#

check_env "$PORT" "PORT"

echo ""
echo "=== UPLOADING TO $PORT === "

arduino-cli upload -p "$PORT" --fqbn "$FQBN" "$SKETCH_DIR"

if [ $? -ne 0 ]; then
    echo "UPLOADING ERROR"
    exit 1
fi

echo "UPLOADING SUCCESS"

BAUDRATE=115200
echo""
read -p "Open Serial Monitor on $PORT? (y/N): " OPEN_MONITOR
if [[ "$OPEN_MONITOR" =~ ^[Yy]$ ]]; then
    echo ""
    echo "=== Serial Monitor ($PORT @ $BAUDRATE baud) ==="
    echo "Press Ctrl+C to exit."
    arduino-cli monitor -p "$PORT" --config baudrate="$BAUDRATE"
fi