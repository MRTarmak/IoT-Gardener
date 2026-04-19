#include <SoftwareSerial.h>
#include <BME280I2C.h>

#define RX_PIN (6)
#define TX_PIN (7)
#define FATAL_ERROR while(1)

//
// Handling WiFi
//

// State machine
enum SystemState : uint8_t
{
    STATE_AP_PROVISIONING = 0,
    STATE_CONNECTING_WIFI = 1,
    STATE_MQTT_READY = 2,
};

SoftwareSerial esp01(RX_PIN, TX_PIN);
SystemState system_state;

void setup()
{
    // Configure UART
    Serial.begin(74880);
    esp01.begin(74880)

}

void loop()
{

}
