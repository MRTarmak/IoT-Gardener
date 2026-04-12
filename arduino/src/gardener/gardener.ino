#include <SoftwareSerial.h>
#include <WiFiEsp.h>
#include <WiFiEspUdp.h>
#include <PubSubClient.h>
#include <BME280I2C.h>
#include <Wire.h>


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
SystemState system_state = STATE_AP_PROVISIONING;

// UART for ESP01
const byte rxPin = 6;
const byte txPin = 7;
SoftwareSerial esp01(rxPin, txPin);

// Access point mode for WiFi provisioning 
WiFiEspUDP udp;
const char *ap_ssid = "ESP_Config";
const char *ap_password = "12345678";

const unsigned int localPort = 8888;

String target_ssid = "";
String target_password = "";

const unsigned int remotePort = 8888;

// 20 seconds to connect
unsigned long stateTimer = 0;
const unsigned long WIFI_TIMEOUT = 20000; 

void onFatalError()
{
    Serial.println("Fatal error. Entering infinite loop.");
    while (true)
        ;
}

void setup()
{
    // Configure UART
    Serial.begin(115200);
    esp01.begin(115200);
    esp01.println("AT+UART_DEF=9600,8,1,0,0");
    delay(1000);
    esp01.begin(9600);
    delay(1000);

    // Initialize ESP WiFi module
    WiFi.init(&esp01);

    if (WiFi.status() == WL_NO_SHIELD)
    {
        Serial.println("ESP01 not found!");
        onFatalError();
    }

    WiFi.reset();

    while (WiFi.status() == WL_IDLE_STATUS)
        delay(100);

    startSoftAPMode(); 
}  

void loop()
{
    switch (system_state)
    {
    case STATE_AP_PROVISIONING:
        handleWiFiProvisioning();
        break;
    case STATE_CONNECTING_WIFI:
        handleWiFiConnection();
        break;
    case STATE_MQTT_READY:
        handleMQTTReady();
        break;
    }
}

void startSoftAPMode()
{
    Serial.println("startSoftAPMode : Starting SoftAP mode...");

    if (WL_CONNECTED == WiFi.beginAP(ap_ssid, 1, ap_password, ENC_TYPE_WPA2_PSK, false))
    {
        Serial.print("startSoftAPMode: SoftAP started. SSID: ");
        Serial.println(ap_ssid);
        Serial.print("startSoftAPMode: SoftAP IP: ");
        Serial.println(WiFi.localIP());

        udp.begin(localPort);
        Serial.print("startSoftAPMode: UDP listening on port ");
        Serial.println(localPort);
        Serial.println("startSoftAPMode: Send SSID and password in format: SSID|PASSWORD");
    }
    else
    {
        Serial.println("startSoftAPMode: Failed to start SoftAP!");
        onFatalError();
    }
}

void handleWiFiProvisioning()
{
    int packetSize = udp.parsePacket();

    // Received nothing
    if (packetSize == 0)
        return;

    char buffer[128] = {0};
    udp.read(buffer, 127);

    String data = String(buffer);
    Serial.print("handleWiFiProvisioning: received: ");
    Serial.println(data);

    // Format: SSID|PASSWORD
    int separator = data.indexOf('|');
    if ((separator <= 0) || (separator >= data.length() - 1))
    {
        udp.beginPacket(udp.remoteIP(), udp.remotePort());
        udp.print("handleWiFiProvisioning : Invalid format. Use SSID|PASSWORD.");
        udp.endPacket();
        return;
    }

    target_ssid = data.substring(0, separator);
    target_password = data.substring(separator + 1);

    // Delete whitespaces
    target_ssid.trim();
    target_password.trim();

    if (target_ssid.length() > 0 && target_password.length() >= 8)
    {
        Serial.print("SSID: ");
        Serial.println(target_ssid);
        Serial.print("Password: ");
        Serial.println(target_password);

        // Send acknowledgement
        udp.beginPacket(udp.remoteIP(), udp.remotePort());
        udp.print("OK");
        udp.endPacket();
        
        udp.stop();
        WiFi.disconnect();
        delay(1000);
        
        stateTimer = millis();
        system_state = STATE_CONNECTING_WIFI;
        WiFi.begin(target_ssid.c_str(), target_password.c_str());
    }
    else
    {
        // Error
        udp.beginPacket(udp.remoteIP(), udp.remotePort());
        udp.print("ERROR: Invalid credentials (password min 8 chars)");
        udp.endPacket();
    }
}

void handleWiFiConnection()
{
    if (WiFi.status() == WL_CONNECTED) {
        // Successfully connected
        udp.begin(remotePort);
        system_state = STATE_MQTT_READY;
        Serial.println("MQTT IS READY.");
    } 
    else if (millis() - stateTimer > WIFI_TIMEOUT) {
        // Cannot connect -- return to AP mode
        Serial.println("WIFI CONNECTION TIMED OUT.");
        Serial.println("RESETTING TO WIFI PROVISIONING.");
        startSoftAPMode();
    }
}

void handleMQTTReady()
{
    // TODO
}

String send_esp_command(String command, const int timeout_ms)
{
    while (esp01.available())
        esp01.read();

    esp01.println(command);
    Serial.print(">> ");
    Serial.println(command);

    String response;
    unsigned long start = millis();

    while (millis() - start < timeout_ms)
    {
        if (esp01.available())
        {
            char c = esp01.read();
            response += c;
            if (c < 0x20 || c > 0x7E)
            {
                Serial.print("[0x");
                Serial.print((byte)c, HEX);
                Serial.print("]");
            }
            else
            {
                Serial.print(c);
            }
        }
        delay(1);
    }

    Serial.println();
    return response;
}