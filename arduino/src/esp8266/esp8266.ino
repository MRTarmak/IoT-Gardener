#include <ESP8266WiFi.h>
#include <WiFiUdp.h>
#include <LittleFS.h>
#include <PubSubClient.h>
#include <time.h>

const char *AP_SSID = "ESP_Config";
const char *AP_PASS = "12345678";
const int UDP_PORT = 8888;

#define STRINGIFY(x) #x
#define QUOTE(MACRO) (STRINGIFY(MACRO))

#ifndef MQ_ENDPOINT
#error "MQ_ENDPOINT not defined"
#endif

#ifndef MQ_USERNAME
#error "MQ_USERNAME not defined"
#endif

#ifndef MQ_PASSWORD
#error "MQ_PASSWORD not defined"
#endif

#ifndef MQ_PORT
#error "MQ_PORT not defined"
#endif

#ifndef TZ_OFFSET
#error "TZ_OFFSET not defined"
#endif

#ifndef MQ_CERT
#error "MQ_CERT not defined"
#endif

const char *mqtt_broker = QUOTE(MQ_ENDPOINT);
const char *mqtt_username = QUOTE(MQ_USERNAME);
const char *mqtt_password = QUOTE(MQ_PASSWORD);
const int mqtt_port = MQ_PORT;
const char *mqtt_topic = "/gardener/telemetry";
const char *mqtt_heartbeat_topic = "/gardener/heartbeat";
const char *ntp_server = "pool.ntp.org";
const long gmt_offset_sec = TZ_OFFSET;
const int daylight_offset_sec = 0;

// ISRG Root X1

static const char ca_cert[] PROGMEM = MQ_CERT;

IPAddress local_ip(192, 168, 4, 1);
IPAddress gateway(192, 168, 4, 1);
IPAddress subnet(255, 255, 255, 0);

WiFiUDP udp;

BearSSL::WiFiClientSecure espClient;
PubSubClient mqtt_client(espClient);

enum State
{
    STATE_AP_PROVISIONING,
    STATE_CONNECTING_WIFI,
    STATE_READY
};

State currentState = STATE_AP_PROVISIONING;

String targetSSID = "";
String targetPASS = "";
String scannedNetworks = "";
unsigned long stateTimer = 0;
unsigned long stateAnnouncementTimer = 0;
const unsigned long WIFI_TIMEOUT = 20000;
const unsigned long STATE_ANNOUNCEMENT_TIMEOUT = 10000;


void announceState(bool force = false)
{
    if (!force && !(millis() - stateAnnouncementTimer > STATE_ANNOUNCEMENT_TIMEOUT))
        return;

    switch (currentState)
    {
    case STATE_AP_PROVISIONING:
        Serial.println("STATE:AP_PROVISIONING");
        break;
    case STATE_CONNECTING_WIFI:
        Serial.println("STATE:CONNECTING_WIFI");
        break;
    case STATE_READY:
        Serial.println("STATE:READY");

        if (mqtt_client.connected())
        {
            // mqtt_client.publish(mqtt_heartbeat_topic, "HEARTBEAT");
        }

        break;
    }

    stateAnnouncementTimer = millis();
}

bool loadCreds()
{
    if (!LittleFS.begin())
    {
        Serial.println("LOG: LittleFS mount failed");
        return false;
    }

    if (!LittleFS.exists("/wifi.txt"))
        return false;

    File f = LittleFS.open("/wifi.txt", "r");

    if (!f)
        return false;

    targetSSID = f.readStringUntil('\n');
    targetPASS = f.readStringUntil('\n');
    f.close();

    targetSSID.trim();
    targetPASS.trim();

    return (targetSSID.length() > 0);
}

void saveCreds(String ssid, String pass)
{
    File f = LittleFS.open("/wifi.txt", "w");
    if (f)
    {
        f.println(ssid);
        f.println(pass);
        f.close();
    }
}

void clearCreds()
{
    LittleFS.begin();
    LittleFS.remove("/wifi.txt");
    Serial.println("LOG: CREDS_CLEARED");
}

void scanWiFi()
{
    int n = WiFi.scanNetworks();
    scannedNetworks = "PONG";
    for (int i = 0; i < n; ++i)
    {
        scannedNetworks += "|";
        scannedNetworks += WiFi.SSID(i);
    }
}

void startAPMode()
{
    currentState = STATE_AP_PROVISIONING;

    announceState(true);

    WiFi.mode(WIFI_AP_STA);

    WiFi.softAPConfig(local_ip, gateway, subnet);
    WiFi.softAP(AP_SSID, AP_PASS);

    udp.begin(UDP_PORT);
    scanWiFi();
}

void startWiFiConnection()
{
    currentState = STATE_CONNECTING_WIFI;

    announceState(true);

    WiFi.mode(WIFI_STA);
    WiFi.disconnect();
    delay(100);
    WiFi.begin(targetSSID.c_str(), targetPASS.c_str());
    stateTimer = millis();
}

void handleUDPProvisioning()
{
    int packetSize = udp.parsePacket();
    if (packetSize > 0)
    {
        char buffer[256] = {0};
        int len = udp.read(buffer, 255);
        buffer[len] = '\0';
        String data = String(buffer);
        data.trim();

        Serial.print("LOG: Received ");
        Serial.println(data);

        if (data == "PING")
        {
            udp.beginPacket(udp.remoteIP(), udp.remotePort());
            udp.print(scannedNetworks);
            udp.endPacket();
        }
        else
        {
            int separator = data.indexOf('|');
            if (separator <= 0)
                return;

            String r_ssid = data.substring(0, separator);
            String r_pass = data.substring(separator + 1);
            r_ssid.trim();
            r_pass.trim();

            if (r_ssid.length() <= 0)
                return;

            udp.beginPacket(udp.remoteIP(), udp.remotePort());
            udp.print("OK");
            udp.endPacket();
            delay(500);

            saveCreds(r_ssid, r_pass);
            ESP.restart();
        }
    }
}

void handleUART()
{
    if (Serial.available())
    {
        String msg = Serial.readStringUntil('\n');
        msg.trim();

        if (msg == "CMD:RESET_WIFI")
        {
            clearCreds();
            ESP.restart();
        }
        else if (msg.startsWith("TLM:") && currentState == STATE_READY && mqtt_client.connected())
        {
            mqtt_client.publish(mqtt_topic, msg.c_str() + 4);
        }
    }
}

void syncTime()
{
    configTime(gmt_offset_sec, daylight_offset_sec, ntp_server);
    Serial.print("LOG: Waiting for NTP time sync: ");

    while (time(nullptr) < 8 * 3600 * 2)
    {
        delay(1000);
        Serial.print(".");
    }

    Serial.println(" Done!");

    Serial.println("LOG: Time synchronized");
    struct tm timeinfo;

    if (getLocalTime(&timeinfo))
    {
        Serial.print("LOG: Current time: ");
        Serial.println(asctime(&timeinfo));
    }
    else
    {
        Serial.println("LOG: Failed to obtain local time");
    }
}

void connectToMQTT()
{
    BearSSL::X509List serverTrustedCA(ca_cert);
    espClient.setTrustAnchors(&serverTrustedCA);

    Serial.print("LOG: mqtt_endpoint: ");
    Serial.println(mqtt_broker);

    Serial.print("LOG: mqtt_port: ");
    Serial.println(mqtt_port);

    Serial.print("LOG: mqtt_password: ");
    Serial.println(mqtt_password);

    Serial.print("LOG: mqtt_username: ");
    Serial.println(mqtt_username);

    while (!mqtt_client.connected())
    {
        String client_id = "esp8266-client-" + String(WiFi.macAddress());
        Serial.printf("LOG: Connecting to MQTT Broker as %s.....\n", client_id.c_str());

        if (mqtt_client.connect(client_id.c_str(), mqtt_username, mqtt_password))
        {
            Serial.println("LOG: Connected to MQTT broker");

            // Publish message upon successful connection
            mqtt_client.publish(mqtt_topic, "Hi EMQX I'm ESP8266 ^^");
        }
        else
        {
            char err_buf[128];
            espClient.getLastSSLError(err_buf, sizeof(err_buf));
            Serial.print("LOG: Failed to connect to MQTT broker, rc=");
            Serial.println(mqtt_client.state());
            Serial.print("LOG: SSL error: ");
            Serial.println(err_buf);
            delay(5000);
        }
    }
}

void setup()
{
    Serial.begin(74880);
    delay(1000);
    Serial.println("LOG: --- ESP01 BOOT ---");

    mqtt_client.setServer(mqtt_broker, mqtt_port);

    if (loadCreds())
    {
        startWiFiConnection();
    }
    else
    {
        startAPMode();
    }
}

void loop()
{
    announceState();
    handleUART();

    switch (currentState)
    {
    case STATE_CONNECTING_WIFI:
        if (WiFi.status() == WL_CONNECTED)
        {
            syncTime();
            currentState = STATE_READY;
        }
        else if (millis() - stateTimer > WIFI_TIMEOUT)
        {
            startAPMode();
        }
        break;

    case STATE_AP_PROVISIONING:
        handleUDPProvisioning();
        break;

    case STATE_READY:
        if (WiFi.status() != WL_CONNECTED)
        {
            startWiFiConnection();
            break;
        }

        if (!mqtt_client.connected())
        {
            connectToMQTT();
        }
        else
        {
            mqtt_client.loop();
        }

        break;
    }
}