#include <SoftwareSerial.h>
#include <WiFiEsp.h>
#include <PubSubClient.h>
#include <BME280I2C.h>

const byte rxPin = 6;
const byte txPin = 7;
SoftwareSerial esp8266(rxPin, txPin);

void setup() 
{
  Serial.begin(9600);
  // esp8266.begin(9600); 
  esp8266.begin(115200); 
  
  Serial.println("Initializing ESP8266...");
  
  // Check that module is available
  sendCommand("AT\r\n", 2000, true);

  // Configure UART
  // sendCommand("AT+UART_CUR=115200,8,1,0,3", 2000, true);
  
  // Station mode (WiFi client)
  sendCommand("AT+CWMODE_CUR=1\r\n", 2000, true);
  
  // Connect to Wi-Fi
  Serial.println("Connecting to Wi-Fi...");
  String connectCmd = String("AT+CWJAP=\"") + WIFI_SSID + "\",\"" + WIFI_PASS + "\"\r\n";
  sendCommand(connectCmd, 10000, true);
  
  // Get IP 
  Serial.println("Checking IP address...");
  sendCommand("AT+CIFSR\r\n", 3000, true);
}

void loop() 
{

  if (esp8266.available()) 
  {
    Serial.write(esp8266.read());
  }
  
  if (Serial.available()) 
  {
    esp8266.write(Serial.read());
  }
}

// Helper func
String sendCommand(String command, const int timeout, boolean debug) 
{
  String response = "";
  
  esp8266.println(command);
  
  long int time = millis();
  
  
  while ((time + timeout) > millis()) 
  {
    while (esp8266.available()) 
    {
      char c = esp8266.read();
      response += c;
    }
  }
  
  if (debug) 
  {
    Serial.print("Command: ");
    Serial.println(command);
    Serial.print("Response: ");
    Serial.println(response);
    Serial.println();
  }
  
  return response;
}