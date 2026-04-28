#include <SoftwareSerial.h>
#include <Adafruit_BME280.h>
#include <Adafruit_ADS1X15.h>
#include <Wire.h>

#include "lcd_ui.h"

#define BUTTON_PAGE (2)
#define BUTTON_RESET (4)
#define RX_PIN (6)
#define TX_PIN (7)
#define FATAL_ERROR while (1)
#define V_PH_NEUTRAL (2.88f)
#define PH_STEP (0.1525f)
#define LCD_RST (8)
#define LCD_RS (10)
#define READ_INTERVAL (60000)
#define BP_DEBOUNCE (200)
#define BR_DEBOUNCE (200)


// State machine
enum SystemState : uint8_t
{
    STATE_AP_PROVISIONING = 0,
    STATE_CONNECTING_WIFI = 1,
    STATE_READY = 2,
};

long bp_last_debounce = 0;
int bp_state = HIGH;
int bp_last_state = HIGH;
bool bp_executed = false;

long br_last_debounce = 0;
int  br_state = HIGH;
int  br_last_state = HIGH;
bool br_executed = false;

Adafruit_BME280 bme;  // 0x76 or 0x77
Adafruit_ADS1115 ads; // 0x48

unsigned long lastReadTime = 0;

SoftwareSerial esp01(RX_PIN, TX_PIN);
SystemState system_state;
lcd_t u8g2(U8G2_R0, LCD_RS, LCD_RST);
LCDUI lcdui(u8g2);

void setup()
{
    // Configure UART
    Serial.begin(74880);
    esp01.begin(74880);

    pinMode(BUTTON_PAGE, INPUT_PULLUP);
    pinMode(BUTTON_RESET, INPUT_PULLUP);

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

void loop()
{
    int bp_reading = digitalRead(BUTTON_PAGE);

    if (bp_reading != bp_last_state)
        bp_last_debounce = millis();

    if ((millis() - bp_last_debounce) > BP_DEBOUNCE)
    {
        if (bp_reading != bp_state)
        {
            bp_state = bp_reading;

            if (bp_state == LOW && !bp_executed)
            {
                lcdui.nextScreen();
                bp_executed = true;
            }

            if (bp_state == HIGH)
                bp_executed = false;
        }
    }

    bp_last_state = bp_reading;

    int br_reading = digitalRead(BUTTON_RESET);

    if (br_reading != br_last_state)
        br_last_debounce = millis();

    if ((millis() - br_last_debounce) > BR_DEBOUNCE)
    {
        if (br_reading != br_state)
        {
            br_state = br_reading;

            if (br_state == LOW && !br_executed)
            {
                esp01.println("CMD:RESET_WIFI");
                br_executed = true;
            }

            if (br_state == HIGH)
                br_executed = false;
        }
    }

    br_last_state = br_reading;


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
    // A0 - pH
    int16_t adc0 = ads.readADC_SingleEnded(0);
    float volts0 = ads.computeVolts(adc0);
    float soilpH = 7.0 + (V_PH_NEUTRAL - volts0) / PH_STEP;

    // A1 - Temp
    int16_t adc1 = ads.readADC_SingleEnded(1);
    float volts1 = ads.computeVolts(adc1);
    float soilTemp = volts1 * 8.0;

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
    float light = volts3 * 200.0;

    // Update screen
    lcdui.uiData.airHum = airHum;
    lcdui.uiData.airTemp = airTemp;
    lcdui.uiData.soilMoist = soilMoist;
    lcdui.uiData.light = light;
    lcdui.uiData.soilPh = soilpH;
    lcdui.uiData.soilTemp = soilTemp;
    lcdui.render();

    String message = "TLM:{";
    message += "\"soilTemperature\":" + String(soilTemp) + ",";
    message += "\"soilMoisture\":" + String(soilMoist) + ",";
    message += "\"soilPh\":" + String(soilpH) + ",";
    message += "\"airTemperature\":" + String(airTemp) + ",";
    message += "\"airHumidity\":" + String(airHum) + ",";
    message += "\"light\":" + String(light) + "}";

    esp01.println(message);
    Serial.println(message);
}
