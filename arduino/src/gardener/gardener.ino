#include <SoftwareSerial.h>
#include <Adafruit_BME280.h>
#include <Adafruit_ADS1X15.h>
#include <Wire.h>

#include "lcd_ui.h"

#define BUTTON (2)
#define RX_PIN (6)
#define TX_PIN (7)

#define FATAL_ERROR while (1)

Adafruit_BME280 bme;  // 0x76 or 0x77
Adafruit_ADS1115 ads; // 0x48

unsigned long lastReadTime = 0;
const unsigned long READ_INTERVAL = 60000;
// const unsigned long READ_INTERVAL = 5000;

// State machine
enum SystemState : uint8_t
{
    STATE_AP_PROVISIONING = 0,
    STATE_CONNECTING_WIFI = 1,
    STATE_READY = 2,
};

SoftwareSerial esp01(RX_PIN, TX_PIN);
SystemState system_state;


#define LCD_RST (8)
#define LCD_RS (10)

lcd_t u8g2(U8G2_R0, LCD_RS, LCD_RST);
LCDUI lcdui(u8g2);

void setup()
{
    // Configure UART
    Serial.begin(74880);
    esp01.begin(74880);

    pinMode(BUTTON, INPUT);

    // I2C
    Wire.begin();

    lcdui.init();

    // BME280
    if (!bme.begin(0x76))
    {
        // Not found
        Serial.println("{\"error\": \"BME280 not found\"}");
    }

    // ADS1115
    // GAIN_TWOTHIRDS allows voltages +/- 6.144V.
    ads.setGain(GAIN_TWOTHIRDS);
    if (!ads.begin())
    {
        Serial.println("{\"error\": \"ADS1115 not found\"}");
    }
}

bool button_start = false;
int buttonState = 0; 

void loop()
{
    buttonState = digitalRead(BUTTON);

    if (buttonState == HIGH) 
    {    
        button_start = true;
    }
    else
    {
        if (button_start)
        {
            lcdui.nextScreen();
            button_start = false;
        }
    }

    if (esp01.available())
    {
        String msg = esp01.readStringUntil('\n');

        msg.trim();

        if (msg.startsWith("STATE:"))
        {
            Serial.println(msg);

            if (msg.startsWith("STATE:READY|"))
            {
                lcdui.setupWiFi(msg.c_str() + 12, msg.length() - 12);
            }
            else if (msg.startsWith("STATE:AP_PROVISIONING"))
            {
                lcdui.resetWiFi();
            }
        }
        else if (msg.startsWith("LOG:"))
        {
            Serial.println(msg);
        }
    }

    if (millis() - lastReadTime >= READ_INTERVAL || lastReadTime == 0)
    {
        lastReadTime = millis();
        readSensors();
    }
}

void readSensors()
{
    // BME280
    float airTemp = bme.readTemperature();
    float airHum = bme.readHumidity();
    float airPres = bme.readPressure() / 100.0 * 0.75006; // mmhg

    // ADS1115
    // A0 - Temp
    int16_t adc0 = ads.readADC_SingleEnded(0);
    float volts0 = ads.computeVolts(adc0);
    float soilTemp = volts0 * 10.0; // TODO

    // A1 - pH
    int16_t adc1 = ads.readADC_SingleEnded(1);
    float volts1 = ads.computeVolts(adc1);
    float soilpH = volts1 * 7 / 2.5; // TODO

    // A2 - Soil Moisture
    int16_t adc2 = ads.readADC_SingleEnded(2);
    float volts2 = ads.computeVolts(adc2);
    float soilMoist = (3.0 - volts2) / (3.0 - 1.2) * 100.0;
    if (soilMoist < 0)
        soilMoist = 0;
    if (soilMoist > 100)
        soilMoist = 100;

    // A3 - Light
    int16_t adc3 = ads.readADC_SingleEnded(3);
    float volts3 = ads.computeVolts(adc3);
    float light = (volts3 / 5.0) * 100.0;


    // Update screen
    lcdui.uiData.airHum = airHum;
    lcdui.uiData.airTemp = airTemp;
    lcdui.uiData.soilMoist = soilMoist;
    lcdui.uiData.light = light;
    lcdui.uiData.soilPh = soilpH;
    lcdui.uiData.soilTemp = soilTemp;
    lcdui.render();

    String message = "TLM:{";
    message += "\"soilTemperature:\"" + String(soilTemp) + ",";
    message += "\"soilMoisture:\"" + String(soilMoist) + ",";
    message += "\"soilPh:\"" + String(soilpH) + ",";
    message += "\"airTemperature:\"" + String(airTemp) + ",";
    message += "\"airHumidity:\"" + String(airHum) + ",";
    message += "\"light:\"" + String(light) + "}";

    esp01.println(message);
    Serial.println(message);
}
