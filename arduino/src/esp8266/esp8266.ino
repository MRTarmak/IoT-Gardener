#include <ESP8266WiFi.h>
#include <WiFiUdp.h>
#include <LittleFS.h>
#include <PubSubClient.h>
#include <time.h>

const char* AP_SSID = "ESP_Config";
const char* AP_PASS = "12345678";
const int UDP_PORT = 8888;

#define STRINGIFY_MACRO(MACRO) ("##MACRO")

const char *mqtt_broker     = STRINGIFY_MACRO(MQ_ENDPOINT);
const char *mqtt_username   = STRINGIFY_MACRO(MQ_USERNAME);
const char *mqtt_password   = STRINGIFY_MACRO(MQ_PASSWORD);
const int   mqtt_port       = 8883;
const char *mqtt_topic      = "telemetry";
const char *ntp_server = "pool.ntp.org"; 
const long gmt_offset_sec = 3 * 3600;
const int  daylight_offset_sec = 0;   

// DigiCert Global Root G2
// expires: Fri, 15 Jan 2038 12:00:00 GMT
static const char ca_cert[]
PROGMEM = R"EOF(
-----BEGIN CERTIFICATE-----
MIIDjjCCAnagAwIBAgIQAzrx5qcRqaC7KGSxHQn65TANBgkqhkiG9w0BAQsFADBh
MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3
d3cuZGlnaWNlcnQuY29tMSAwHgYDVQQDExdEaWdpQ2VydCBHbG9iYWwgUm9vdCBH
MjAeFw0xMzA4MDExMjAwMDBaFw0zODAxMTUxMjAwMDBaMGExCzAJBgNVBAYTAlVT
MRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5j
b20xIDAeBgNVBAMTF0RpZ2lDZXJ0IEdsb2JhbCBSb290IEcyMIIBIjANBgkqhkiG
9w0BAQEFAAOCAQ8AMIIBCgKCAQEAuzfNNNx7a8myaJCtSnX/RrohCgiN9RlUyfuI
2/Ou8jqJkTx65qsGGmvPrC3oXgkkRLpimn7Wo6h+4FR1IAWsULecYxpsMNzaHxmx
1x7e/dfgy5SDN67sH0NO3Xss0r0upS/kqbitOtSZpLYl6ZtrAGCSYP9PIUkY92eQ
q2EGnI/yuum06ZIya7XzV+hdG82MHauVBJVJ8zUtluNJbd134/tJS7SsVQepj5Wz
tCO7TG1F8PapspUwtP1MVYwnSlcUfIKdzXOS0xZKBgyMUNGPHgm+F6HmIcr9g+UQ
vIOlCsRnKPZzFBQ9RnbDhxSJITRNrw9FDKZJobq7nMWxM4MphQIDAQABo0IwQDAP
BgNVHRMBAf8EBTADAQH/MA4GA1UdDwEB/wQEAwIBhjAdBgNVHQ4EFgQUTiJUIBiV
5uNu5g/6+rkS7QYXjzkwDQYJKoZIhvcNAQELBQADggEBAGBnKJRvDkhj6zHd6mcY
1Yl9PMWLSn/pvtsrF9+wX3N3KjITOYFnQoQj8kVnNeyIv/iPsGEMNKSuIEyExtv4
NeF22d+mQrvHRAiGfzZ0JFrabA0UWTW98kndth/Jsw1HKj2ZL7tcu7XUIOGZX1NG
Fdtom/DzMNU+MeKNhJ7jitralj41E6Vf8PlwUHBHQRFXGU7Aj64GxJUTFy8bJZ91
8rGOmaFvE7FBcf6IKshPECBV1/MUReXgRPTqh5Uykw7+U0b6LJ3/iyK5S9kJRaTe
pLiaWN0bfVKfjllDiIGknibVb63dDcY3fe0Dkhvld1927jyNxF1WW6LZZm6zNTfl
MrY=
-----END CERTIFICATE-----
)EOF";

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
const unsigned long WIFI_TIMEOUT = 20000;

bool loadCreds() 
{
  if (!LittleFS.begin()) 
  {
    Serial.println("FS_ERROR: LittleFS mount failed");
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
  Serial.println("STATUS:CREDS_CLEARED");
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
  Serial.println("STATUS:AP_MODE");

  WiFi.mode(WIFI_AP_STA);

  WiFi.softAPConfig(local_ip, gateway, subnet);
  WiFi.softAP(AP_SSID, AP_PASS);

  udp.begin(UDP_PORT);
  scanWiFi(); 
}

void startWiFiConnection() 
{
  currentState = STATE_CONNECTING_WIFI;
  Serial.println("STATUS:CONNECTING");

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

    Serial.print("RECEIVED:");
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
      r_ssid.trim(); r_pass.trim();

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
    // else if (msg.startsWith("TLM|") && currentState == STATE_READY) 
    // {
    //   mqtt.publish(TOPIC_TELEMETRY, msg.c_str());
    // }
  }
}


void syncTime() 
{
    configTime(gmt_offset_sec, daylight_offset_sec, ntp_server);
    Serial.print("Waiting for NTP time sync: ");
    
    while (time(nullptr) < 8 * 3600 * 2) 
    {
      delay(1000);
      Serial.print(".");
    }
    
    Serial.println("Time synchronized");
    struct tm timeinfo;
    
    if (getLocalTime(&timeinfo)) 
    {
      Serial.print("Current time: ");
    Serial.println(asctime(&timeinfo));
    } 
    else 
    {
      Serial.println("Failed to obtain local time");
    }
}

void connectToMQTT()
{
    BearSSL::X509List serverTrustedCA(ca_cert);
    espClient.setTrustAnchors(&serverTrustedCA);

    while (!mqtt_client.connected()) 
    {
      String client_id = "esp8266-client-" + String(WiFi.macAddress());
      Serial.printf("Connecting to MQTT Broker as %s.....\n", client_id.c_str());
      
      if (mqtt_client.connect(client_id.c_str(), mqtt_username, mqtt_password)) 
      {
        Serial.println("Connected to MQTT broker");
        mqtt_client.subscribe(mqtt_topic);
        // Publish message upon successful connection
        mqtt_client.publish(mqtt_topic, "Hi EMQX I'm ESP8266 ^^");
      } 
      else 
      {
        char err_buf[128];
        espClient.getLastSSLError(err_buf, sizeof(err_buf));
        Serial.print("Failed to connect to MQTT broker, rc=");
        Serial.println(mqtt_client.state());
        Serial.print("SSL error: ");
        Serial.println(err_buf);
        delay(5000);
      }
  }
}

void setup() 
{
  Serial.begin(74880);
  delay(1000);
  Serial.println("\n--- ESP01 BOOT ---");

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


      Serial.println("STATUS:READY");
      if (!mqtt_client.connected()) {
        connectToMQTT();
      }
      mqtt_client.loop();
      
      delay(1000);
      break;
  }
}