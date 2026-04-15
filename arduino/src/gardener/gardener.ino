#include <SoftwareSerial.h>
#include <WiFiEsp.h>
#include <WiFiEspUdp.h>
#include <PubSubClient.h>
#include <BME280I2C.h>

#define RX_PIN (6)
#define TX_PIN (7)
#define LOCAL_PORT (8888)
#define WIFI_TIMEOUT (20000)
#define AP_SSID "ESP_Config"
#define AP_PASS "12345678"
#define ESP01_BAUDRATE 9600
#define MQTT_TOPIC "gardener-telemetry"

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

char target_ssid[32] = {};
char target_password[32] = {};
SoftwareSerial esp01(RX_PIN, TX_PIN);
WiFiEspUDP udp;
unsigned long stateTimer = 0;
const unsigned short remotePort = 8888;
SystemState system_state;

//
// MQTT
//

#ifndef MQ_ENDPOINT
#error "MQ_ENDPOINT is not defined"
#else
const char *mqtt_broker = MQ_ENDPOINT;
#endif

#ifndef MQ_PORT
#error "MQ_PORT is not defined"
#else
const int mqtt_port = MQ_PORT;
#endif

#ifndef MQ_USERNAME
#error "MQ_USERNAME is not defined"
#else
const char *mqtt_username = MQ_USERNAME;
#endif

#ifndef MQ_PASSWORD
#error "MQ_PASSWORD is not defined"
#else
const char *mqtt_password = MQ_PASSWORD;
#endif


WiFiEspClient g_esp_client; // 2060 bytes
PubSubClient g_mqtt_client{g_esp_client}; // 286 bytes 

void setup()
{
    // Configure UART
    Serial.begin(115200);
    esp01.begin(115200);
    esp01.print("AT+UART_DEF=9600,8,1,0,0");
    delay(1000);
    esp01.begin(9600);
    delay(1000);

    // Initialize ESP WiFi module
    WiFi.init(&esp01);

    if (WiFi.status() == WL_NO_SHIELD)
    {
        Serial.println("ESP01 not found!");
        FATAL_ERROR;
    }

    WiFi.reset();

    while (WiFi.status() == WL_IDLE_STATUS)
        delay(100);

    startSoftAPMode();
    g_mqtt_client.setServer(mqtt_broker, mqtt_port);

}


void loop()
{
    if (system_state == STATE_AP_PROVISIONING)
    {
		short packetSize = udp.parsePacket();

	    // Received nothing
	    if (packetSize == 0)
		    return;

	    char buffer[64] = {0};
	    udp.read(buffer, 63);

		short separator = -1;
		short end = -1;
		for (short i = 0; i < 64; i++)
		{
			if (separator < 0 && buffer[i] == '|')
				separator = i;

			if (end < 0 && buffer[i] <= 0x20)
				end = i;
		}

        Serial.print("Accepted: ");
        Serial.println(buffer);

	    if (separator > 0 && end > separator)
	    {
			memcpy(target_ssid, buffer, separator);
			memcpy(target_password, buffer + separator + 1, end - separator - 1);
			target_ssid[separator] = 0;
			target_password[end - separator - 1] = 0;

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
		    WiFi.begin(target_ssid, target_password);
            Serial.println("State = CONNECTING WIFI");
	    }
	    else
	    {
		    // Error
		    udp.beginPacket(udp.remoteIP(), udp.remotePort());
		    udp.print("ERROR: Invalid credentials");
		    udp.endPacket();
	    }
    }
    else if (system_state == STATE_CONNECTING_WIFI)
    {   
	    if (WiFi.status() == WL_CONNECTED)
	    {
		    // Successfully connected
		    system_state = STATE_MQTT_READY;
		    Serial.println("MQTT is ready.");
            return;
	    }
	    else if (millis() - stateTimer > WIFI_TIMEOUT)
	    {
		    // Cannot connect -- return to AP mode
		    Serial.println("WiFi connection timed out.");
		    startSoftAPMode();
            return;
	    }
    }
    else
    {
		connectToMQTTBroker();
        return;
    }
}


void startSoftAPMode()
{
	system_state = STATE_AP_PROVISIONING;

    if (WL_CONNECTED == WiFi.beginAP(AP_SSID, 1, AP_PASS, ENC_TYPE_WPA2_PSK, false))
    {
        Serial.print("SoftAP started. SSID: ");
        Serial.println(AP_SSID);
        Serial.print("SoftAP IP: ");
        Serial.println(WiFi.localIP());

        udp.begin(LOCAL_PORT);
        Serial.print("UDP listening on port ");
        Serial.println(LOCAL_PORT);
	}
    else
    {
        Serial.println("FATAL : Failed to start SoftAP");
	    FATAL_ERROR;
    }
}


void connectToMQTTBroker()
{
    while (!g_mqtt_client.connected())
    {
        String client_id = "esp-client-1";
        Serial.print("Connecting to MQTT Broker as ");
        Serial.println(client_id.c_str());
        if (g_mqtt_client.connect(client_id.c_str(), mqtt_username, mqtt_password))
        {
            Serial.println("Connected to MQTT broker");
            g_mqtt_client.subscribe(MQTT_TOPIC);

            // Publish message upon successful connection
            g_mqtt_client.publish(MQTT_TOPIC, "Hello to EMQX from ESP01");
        }
        else
        {
            Serial.print("Failed to connect to MQTT broker, rc=");
            Serial.print(g_mqtt_client.state());
            Serial.println(" try again in 5 seconds");
            delay(5000);
        }
    }
}