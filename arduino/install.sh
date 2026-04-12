#! /usr/bin/bash 

FQBN="arduino:avr:uno"
SKETCH_DIR="./src/gardener"
LIBRARIES_DIR="./libraries"

# Check that arduino-cli is installed
if ! command -v arduino-cli &> /dev/null; then
    echo "ERROR: arduino-cli is required."
    exit 1
fi

PORT=$1
shift
EXTRA_FLAGS="$@"

# Base compilation command
COMPILE_CMD=(arduino-cli compile --fqbn "$FQBN" --libraries "$LIBRARIES_DIR")

# Add extra flags
if [ -n "$EXTRA_FLAGS" ]; then
    echo "Using extra flags: $EXTRA_FLAGS"
    COMPILE_CMD+=(--build-property "build.extra_flags=$EXTRA_FLAGS")
fi

COMPILE_CMD+=("$SKETCH_DIR")

echo ""
echo "=== COMPILING PROJECT ==="
"${COMPILE_CMD[@]}"

if [ $? -ne 0 ]; then
    echo "COMPILATION ERROR"
    
    exit 1
fi

echo "COMPILATION SUCCESS"

# Upload script
if [ -z "$PORT" ]; then
    echo "WARNING: port is not specified. Skipping upload."
    exit 0
fi

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