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

#
# Compile
#

# Base compilation command
COMPILE_CMD=(arduino-cli compile --fqbn "$FQBN" --libraries "$LIBRARIES_DIR")

if [ -n "$EXTRA_FLAGS" ]; then
    echo "Using extra flags: $EXTRA_FLAGS"
    MACRO_FLAGS+="$EXTRA_FLAGS"
fi

if [ -n "$MACRO_FLAGS" ]; then
    COMPILE_CMD+=(--build-property "build.extra_flags=$MACRO_FLAGS")
fi

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

./serial_monitor