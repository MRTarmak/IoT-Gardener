#include <U8g2lib.h>

typedef unsigned char uint8_t;

typedef U8G2_ST7920_128X64_1_HW_SPI lcd_t;

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

int renderCommon(U8G2_ST7920_128X64_1_HW_SPI &lcd, const String *items, const uint8_t itemsSize)
{
    if (itemsSize == 0)
    {
        return -1;
    }

    lcd.firstPage();
    do
    {
        // 1. Внешняя рамка
        lcd.drawFrame(0, 0, 128, 64);

        // 2. Заголовок
        lcd.setFont(u8g2_font_6x12_t_cyrillic);
        const int titleY = lcd.getAscent() + 2; 
        const int titleW = lcd.getUTF8Width(items[0].c_str());
        const int titleX = (128 - titleW) / 2;
        lcd.drawUTF8(titleX, titleY, items[0].c_str());

        // 3. Тело списка
        const uint8_t bodyItemsSize = itemsSize - 1;
        const int leftPadding = 8;
        const int bodyTop = titleY + 3;
        const int bodyHeight = 64 - bodyTop - 2;
        
        lcd.setFont(u8g2_font_5x8_t_cyrillic);
        const int lineHeight = lcd.getMaxCharHeight() + 1;
        const int blockHeight = lineHeight * bodyItemsSize;
        const int topOffset = (bodyHeight > blockHeight) ? (bodyHeight - blockHeight) / 2 : 0;
        const int firstLineY = bodyTop + topOffset + lcd.getAscent();

        for (int i = 0; i < bodyItemsSize; i++)
        {
            const int y = firstLineY + lineHeight * i;
            if (y < 64) {
                lcd.drawUTF8(leftPadding, y, items[i + 1].c_str());
            }
        }

    } while (lcd.nextPage()); // Здесь данные отправляются на дисплей порциями

    return 0;
}

// int renderCommon(U8G2 &lcd, const String *items, const uint8_t itemsSize)
// {
//     if (itemsSize == 0)
//     {
//         return -1;
//     }

//     lcd.clearBuffer();

//     // Outter frame
//     lcd.drawFrame(0, 0, 128, 64);

//     // Title on top, centered.
//     lcd.setFont(u8g2_font_6x12_t_cyrillic);
//     const int titleY = lcd.getAscent() + 1;
//     const int titleW = lcd.getStrWidth(items[0].c_str());
//     const int titleX = (128 - titleW) / 2;
//     lcd.drawUTF8(titleX, titleY, items[0].c_str());

//     // Body lines centered vertically in the remaining area and left-aligned.
//     const uint8_t bodyItemsSize = itemsSize - 1;
//     const int leftPadding = 8;
//     const int bodyTop = titleY + 3;
//     const int bodyHeight = 64 - bodyTop - 2;
//     lcd.setFont(u8g2_font_5x8_t_cyrillic);
//     const int lineHeight = lcd.getMaxCharHeight();
//     const int blockHeight = lineHeight * bodyItemsSize;
//     const int topOffset = (bodyHeight > blockHeight) ? (bodyHeight - blockHeight) / 2 : 0;
//     const int firstLineY = bodyTop + topOffset + lcd.getAscent();

//     for (int i = 0; i < bodyItemsSize; i++)
//     {
//         const int y = firstLineY + lineHeight * i;
//         lcd.drawUTF8(leftPadding, y, items[i + 1].c_str());
//     }

//     lcd.sendBuffer();

//     return 0;
// }

struct LCDUI
{
    LCDUI(lcd_t &lcd) : lcd(lcd) {};

    lcd_t &lcd;
    UIData uiData = UIData();
    ScreenType currentScreen = ScreenType::Settings;
    const uint8_t totalScreens = 3;

    int render()
    {
        String items[4];
        switch (currentScreen)
        {
        case ScreenType::TelemetrySoil:
            items[0] = "SOIL";
            items[1] = "Temperature: " + String(uiData.soilTemp) + " C";
            items[2] = "Moisture: " + String(uiData.soilMoist) + "%";
            items[3] = "pH: " + String(uiData.soilPh);
            return renderCommon(lcd, items, 4);
        case ScreenType::TelemetryEnv:
            items[0] = "ENVIRONMENT";
            items[1] = "Temperature: " + String(uiData.airTemp) + " C";
            items[2] = "Humidity: " + String(uiData.airHum) + "%";
            items[3] = "Light: " + String(uiData.light);
            return renderCommon(lcd, items, 4);
        case ScreenType::Settings:
            items[0] = "Settings";
            items[1] = "Mode: " + String(uiData.mode == Mode::Broadcast ? "Working" : "Configuring");
            items[2] = "WiFi: " + String(uiData.mode == Mode::Broadcast ? uiData.ssid : "ESP_Config");
            return renderCommon(lcd, items, 3);
        default:
            return -1;
        }
    }

    int init()
    {
        lcd.begin();
        lcd.enableUTF8Print();
        return render();
    }

    int nextScreen()
    {
        currentScreen = (ScreenType)(((uint8_t)currentScreen + 1) % totalScreens);
        return render();
    }

    int setupWiFi(const char *ssid, int size)
    {
        for (int i = 0; i < size && (i < sizeof(uiData.ssid) - 1); i++)
        {
            uiData.ssid[i] = ssid[i];
        }
        uiData.ssid[sizeof(uiData.ssid) - 1] = '\0';
        uiData.mode = Mode::Broadcast;
        return render();
    }

    int resetWiFi()
    {
        uiData.ssid[0] = '\0';
        uiData.mode = Mode::Setup;
        return render();
    }
};
