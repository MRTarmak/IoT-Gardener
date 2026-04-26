#pragma once
#include <cstdio>
#include <string>
#include <U8g2lib.h>

typedef unsigned char uint8_t;

enum ScreenType : uint8_t
{
    TelemetrySoil = 0,
    TelemetryEnv = 1,
    Settings = 2
};

enum Mode : bool
{
    Setup = false,
    Broadcast = true
};

struct UIData
{
    // Telemetry Soil Screen
    float soilTemp = 0;
    float soilMoist = 0;
    float soilPh = 0;
    // Telemetry Env Screen
    float airTemp = 0;
    float airHum = 0;
    float light = 0;
    // Settings Screen
    Mode mode = Mode::Setup;
    char ssid[32] = "";
};

std::string toFixed2(float value)
{
    char buf[16];
    snprintf(buf, sizeof(buf), "%.2f", value);
    return std::string(buf);
}

int renderCommon(U8G2 &lcd, const std::string items[], const uint8_t itemsSize)
{
    if (itemsSize == 0)
    {
        return -1;
    }

    lcd.clearBuffer();

    // Outter frame
    lcd.drawFrame(0, 0, 128, 64);

    // Title on top, centered.
    lcd.setFont(u8g2_font_6x12_t_cyrillic);
    const int titleY = lcd.getAscent() + 1;
    const int titleW = lcd.getStrWidth(items[0].c_str());
    const int titleX = (128 - titleW) / 2;
    lcd.drawUTF8(titleX, titleY, items[0].c_str());

    // Body lines centered vertically in the remaining area and left-aligned.
    const uint8_t bodyItemsSize = itemsSize - 1;
    const int leftPadding = 8;
    const int bodyTop = titleY + 3;
    const int bodyHeight = 64 - bodyTop - 2;
    lcd.setFont(u8g2_font_5x8_t_cyrillic);
    const int lineHeight = lcd.getMaxCharHeight();
    const int blockHeight = lineHeight * bodyItemsSize;
    const int topOffset = (bodyHeight > blockHeight) ? (bodyHeight - blockHeight) / 2 : 0;
    const int firstLineY = bodyTop + topOffset + lcd.getAscent();

    for (int i = 0; i < bodyItemsSize; i++)
    {
        const int y = firstLineY + lineHeight * i;
        lcd.drawUTF8(leftPadding, y, items[i + 1].c_str());
    }

    lcd.sendBuffer();

    return 0;
}

template <ScreenType T>
class Screen
{
public:
    int render(UIData &uiData);
};

template <>
class Screen<ScreenType::TelemetrySoil>
{
    U8G2 &lcd;

public:
    Screen(U8G2 &lcd) : lcd(lcd) {}

    int render(UIData &uiData)
    {
        const uint8_t itemsSize = 4;
        const std::string items[itemsSize] = {
            "Почва",
            "Температура: " + toFixed2(uiData.soilTemp) + " °C",
            "Влажность: " + toFixed2(uiData.soilMoist) + "%",
            "Кислотность (pH): " + toFixed2(uiData.soilPh),
        };

        return renderCommon(lcd, items, itemsSize);
    }
};

template <>
class Screen<ScreenType::TelemetryEnv>
{
    U8G2 &lcd;

public:
    Screen(U8G2 &lcd) : lcd(lcd) {}

    int render(UIData &uiData)
    {
        const uint8_t itemsSize = 4;
        const std::string items[itemsSize] = {
            "Среда",
            "Температура: " + toFixed2(uiData.airTemp) + " °C",
            "Влажность: " + toFixed2(uiData.airHum) + "%",
            "Освещенность: " + toFixed2(uiData.light) + " lx",
        };

        return renderCommon(lcd, items, itemsSize);
    }
};

template <>
class Screen<ScreenType::Settings>
{
    U8G2 &lcd;

public:
    Screen(U8G2 &lcd) : lcd(lcd) {}

    int render(UIData &uiData)
    {
        const uint8_t itemsSize = 3;
        const std::string items[itemsSize] = {
            "Настройки",
            "Режим: " + std::string(uiData.mode == Mode::Broadcast ? "Передача" : "Настройка"),
            "WiFi: " + std::string(uiData.mode == Mode::Broadcast ? uiData.ssid : "ESP_Config"),
        };

        return renderCommon(lcd, items, itemsSize);
    }
};

class LCDUI
{
    U8G2 &lcd;

    UIData uiData = UIData();

    Screen<ScreenType::TelemetrySoil> telemetrySoilScreen = Screen<ScreenType::TelemetrySoil>(lcd);
    Screen<ScreenType::TelemetryEnv> telemetryEnvScreen = Screen<ScreenType::TelemetryEnv>(lcd);
    Screen<ScreenType::Settings> settingsScreen = Screen<ScreenType::Settings>(lcd);

    ScreenType currentScreen = ScreenType::TelemetrySoil;
    const uint8_t totalScreens = 3;

public:
    LCDUI(U8G2 &lcd) : lcd(lcd)
    {
        this->lcd.enableUTF8Print();
    };

    void setSoilTemp(float temp) { uiData.soilTemp = temp; }
    void setSoilMoist(float moist) { uiData.soilMoist = moist; }
    void setSoilPh(float ph) { uiData.soilPh = ph; }
    void setAirTemp(float temp) { uiData.airTemp = temp; }
    void setAirHum(float hum) { uiData.airHum = hum; }
    void setLight(float light) { uiData.light = light; }
    void setMode(Mode mode) { uiData.mode = mode; }
    void setSSID(const char *ssid)
    {
        strncpy(uiData.ssid, ssid, sizeof(uiData.ssid) - 1);
        uiData.ssid[sizeof(uiData.ssid) - 1] = '\0';
    }

    int render()
    {
        switch (currentScreen)
        {
        case ScreenType::TelemetrySoil:
            return telemetrySoilScreen.render(uiData);
        case ScreenType::TelemetryEnv:
            return telemetryEnvScreen.render(uiData);
        case ScreenType::Settings:
            return settingsScreen.render(uiData);
        default:
            return -1;
        }
    }

    int nextScreen()
    {
        currentScreen = (ScreenType)(((uint8_t)currentScreen + 1) % totalScreens);
        return render();
    }
};
