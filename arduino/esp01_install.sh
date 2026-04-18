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

# Check env
check_env "$EMQX_ENDPOINT" "EMQX_ENDPOINT"
check_env "$EMQX_PORT" "EMQX_PORT"
check_env "$EMQX_USERNAME" "EMQX_USERNAME"
check_env "$EMQX_PASSWORD" "EMQX_PASSWORD"
check_env "$PORT" "PORT"

#
# Compile
#

COMPILE_CMD=(arduino-cli compile --fqbn "$FQBN" --libraries "$LIBRARIES_DIR")

MACRO_FLAGS="-DMQ_ENDPOINT=\$EMQX_ENDPOINT "
MACRO_FLAGS+="-DMQ_PORT=$EMQX_PORT "
MACRO_FLAGS+="-DMQ_USERNAME=$EMQX_USERNAME "
MACRO_FLAGS+="-DMQ_PASSWORD=$EMQX_PASSWORD "


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
echo "=== ВНИМАНИЕ: РУЧНОЙ ПЕРЕХОД В РЕЖИМ ПРОШИВКИ ==="
echo "1. Убедись, что на Arduino UNO стоит перемычка RESET -> GND"
echo "2. Подключи пин GPIO0 на ESP-01 к GND"
echo "3. Кратковременно передерни питание ESP-01 (или коснись пином RST земли)"
read -p "Нажми Enter, когда будешь готов к прошивке..."

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

#
# Serial monitor
#

echo ""
echo "=== ВНИМАНИЕ: ПЕРЕХОД В РАБОЧИЙ РЕЖИМ ==="
echo "1. ОТКЛЮЧИ пин GPIO0 от GND (переведи на 3.3V)"
echo "2. Кратковременно передерни питание ESP-01 (рестарт)"
read -p "Открыть Serial Monitor на $PORT? (y/N): " OPEN_MONITOR

if [[ "$OPEN_MONITOR" =~ ^[Yy]$ ]]; then
    BAUDRATE=74880
    echo ""
    echo "=== Serial Monitor ($PORT @ $BAUDRATE baud) ==="
    echo "Press Ctrl+C to exit."
    arduino-cli monitor -p "$PORT" --config baudrate="$BAUDRATE"
fi