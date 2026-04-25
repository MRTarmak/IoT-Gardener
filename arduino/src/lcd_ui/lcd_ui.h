#pragma once
#include <stdexcept>
#include <U8g2lib.h>

enum Input
{
    Up,
    Down,
    Select,
    Back
};

class Screen
{
protected:
    U8G2 &lcd;

public:
    explicit Screen(U8G2 &lcd) : lcd(lcd) {};
    virtual void render() = 0;
    virtual void handleInput(Input input) = 0;
    virtual Screen &changeScreen() = 0;
    virtual Screen &returnToPreviousScreen() = 0;
    virtual ~Screen() = default;
};

class TelemetryScreen : public Screen
{
    Screen &mainMenuScreen;

    enum Option
    {
        SoilMoisture,
        AirHumidity,
        SoilPh,
        SoilTemperature,
        AirTemperature,
        Light
    } selectedOption = Option::SoilMoisture;

    const uint8_t optionsSize = 6;

    bool isScrolled = false;

public:
    TelemetryScreen(U8G2 &lcd, Screen &mainMenuScreen) : Screen(lcd), mainMenuScreen(mainMenuScreen) {};

    // TODO добавить получение телеметрии
    void render() override
    {
        const uint8_t itemsSize = 6;

        const char *items[itemsSize] = {
            "Soil Moisture: ",
            "Air Humidity: ",
            "Soil pH: ",
            "Soil Temp.: ",
            "Air Temp.: ",
            "Light: "};

        lcd.clearBuffer();
        lcd.setFont(u8g2_font_6x10_tf);

        // Внешняя рамка
        lcd.drawFrame(0, 0, 128, 64);

        // Параметры текста
        const int lineH = 12;                // шаг строк
        const int maxLines = 5;              // отображаем 5 строк, 6-я - скрытая
        const int blockH = lineH * maxLines; // высота блока из 5 строк
        const int topY = (64 - blockH) / 2;  // верх блока трех строк
        // basline, scrolled baseline
        int y[itemsSize], sy[itemsSize];
        for (int i = 0; i < maxLines; i++)
        {
            y[i] = topY + 10 + lineH * i;
            sy[i + 1] = y[i];
        }

        // Центрирование по X
        int w[itemsSize], x[itemsSize];
        for (int i = 0; i < itemsSize; i++)
        {
            w[i] = lcd.getStrWidth(items[i]);
            x[i] = (128 - w[i]) / 2;
        }

        // Selected option validation
        if (selectedOption >= optionsSize)
            throw std::runtime_error("Invalid option selected");

        // Rendering
        int i = 0;
        for (; i < itemsSize; i++)
        {
            if (!isScrolled)
            {
                if (i == 5)
                    continue; // 6-я строка скрыта
                else if (i == static_cast<int>(selectedOption))
                {
                    lcd.drawBox(6, y[i] - 10, 116, 12);
                    lcd.setDrawColor(0);
                    lcd.drawStr(x[i], y[i], items[i]);
                    lcd.setDrawColor(1);
                }
                else
                {
                    lcd.drawStr(x[i], y[i], items[i]);
                }
            }
            else
            {
                if (i == 0)
                    continue; // 1-я строка скрыта
                else if (i == static_cast<int>(selectedOption))
                {
                    lcd.drawBox(6, sy[i] - 10, 116, 12);
                    lcd.setDrawColor(0);
                    lcd.drawStr(x[i], sy[i], items[i]);
                    lcd.setDrawColor(1);
                }
                else
                {
                    lcd.drawStr(x[i], sy[i], items[i]);
                }
            }
        }

        lcd.sendBuffer();
    };

    void handleInput(Input input) override
    {
        switch (input)
        {
        case Input::Up:
            selectedOption = static_cast<Option>((selectedOption - 1 + optionsSize) % optionsSize);
            if (isScrolled && selectedOption == Option::SoilMoisture)
            {
                isScrolled = false;
            }
            break;
        case Input::Down:
            selectedOption = static_cast<Option>((selectedOption + 1) % optionsSize);
            if (!isScrolled && selectedOption == Option::Light)
            {
                isScrolled = true;
            }
            break;
        case Input::Select:
            break;
        case Input::Back:
            returnToPreviousScreen();
            break;
        default:
            throw std::runtime_error("Invalid input");
        }
    };

    Screen &changeScreen() override
    {
        return *this;
    };

    Screen &returnToPreviousScreen() override
    {
        return mainMenuScreen;
    };
};

// TODO добавить получение текущего режима и сети
class SettingsScreen : public Screen
{
    Screen &mainMenuScreen;

    enum Option
    {
        Mode,
        CurrentNetwork,
        ResetNetwork
    } selectedOption = Option::Mode;

    const uint8_t optionsSize = 3;

public:
    SettingsScreen(U8G2 &lcd, Screen &mainMenuScreen) : Screen(lcd), mainMenuScreen(mainMenuScreen) {};

    void render() override
    {
        const char *item1 = "Mode";
        const char *item2 = "Current Network";
        const char *item3 = "Reset Network";

        lcd.clearBuffer();
        lcd.setFont(u8g2_font_6x10_tf);

        // Внешняя рамка
        lcd.drawFrame(0, 0, 128, 64);

        // Параметры текста
        const int lineH = 12; // шаг строк
        const int blockH = lineH * 3;
        const int topY = (64 - blockH) / 2; // верх блока трех строк
        const int y1 = topY + 10;           // baseline 1-й строки
        const int y2 = y1 + lineH;          // baseline 2-й строки
        const int y3 = y2 + lineH;          // baseline 3-й строки

        // Центрирование по X
        const int w1 = lcd.getStrWidth(item1);
        const int w2 = lcd.getStrWidth(item2);
        const int w3 = lcd.getStrWidth(item3);
        const int x1 = (128 - w1) / 2;
        const int x2 = (128 - w2) / 2;
        const int x3 = (128 - w3) / 2;

        switch (selectedOption)
        {
        case Option::Mode:
            lcd.drawBox(6, y1 - 10, 116, 12); // плашка под 1-й строкой
            lcd.setDrawColor(0);              // текст "вычитается" (белый на черном)
            lcd.drawStr(x1, y1, item1);
            lcd.setDrawColor(1);
            lcd.drawStr(x2, y2, item2);
            lcd.drawStr(x3, y3, item3);
            break;
        case Option::CurrentNetwork:
            lcd.drawStr(x1, y1, item1);
            lcd.drawBox(6, y2 - 10, 116, 12); // плашка под 2-й строкой
            lcd.setDrawColor(0);
            lcd.drawStr(x2, y2, item2);
            lcd.setDrawColor(1);
            lcd.drawStr(x3, y3, item3);
            break;
        case Option::ResetNetwork:
            lcd.drawStr(x1, y1, item1);
            lcd.drawStr(x2, y2, item2);
            lcd.drawBox(6, y3 - 10, 116, 12); // плашка под 3-й строкой
            lcd.setDrawColor(0);
            lcd.drawStr(x3, y3, item3);
            lcd.setDrawColor(1);
            break;
        default:
            throw std::runtime_error("Invalid option selected");
        }

        lcd.sendBuffer();
    };

    void handleInput(Input input) override
    {
        switch (input)
        {
        case Input::Up:
            selectedOption = static_cast<Option>((selectedOption - 1 + optionsSize) % optionsSize);
            break;
        case Input::Down:
            selectedOption = static_cast<Option>((selectedOption + 1) % optionsSize);
            break;
        case Input::Select:
            if (selectedOption == Option::ResetNetwork)
            {
                // TODO вызов сброса сети
            }
            break;
        case Input::Back:
            returnToPreviousScreen();
            break;
        default:
            throw std::runtime_error("Invalid input");
        }
    };

    Screen &changeScreen() override
    {
        return *this;
    };

    Screen &returnToPreviousScreen() override
    {
        return mainMenuScreen;
    };
};

class MainMenuScreen : public Screen
{
    Screen &telemetryScreen;
    Screen &settingsScreen;

    enum Option
    {
        Telemetry,
        Settings
    } selectedOption = Option::Telemetry;

    const uint8_t optionsSize = 2;

public:
    MainMenuScreen(U8G2 &lcd, Screen &telemetryScreen, Screen &settingsScreen) : Screen(lcd),
                                                                                 telemetryScreen(telemetryScreen),
                                                                                 settingsScreen(settingsScreen) {}

    void render() override
    {
        const char *item1 = "Telemetry";
        const char *item2 = "Settings";

        lcd.clearBuffer();
        lcd.setFont(u8g2_font_6x10_tf);

        // Внешняя рамка
        lcd.drawFrame(0, 0, 128, 64);

        // Параметры текста
        const int lineH = 12; // шаг строк
        const int blockH = lineH * 2;
        const int topY = (64 - blockH) / 2; // верх блока двух строк
        const int y1 = topY + 10;           // baseline 1-й строки
        const int y2 = y1 + lineH;          // baseline 2-й строки

        // Центрирование по X
        const int w1 = lcd.getStrWidth(item1);
        const int w2 = lcd.getStrWidth(item2);
        const int x1 = (128 - w1) / 2;
        const int x2 = (128 - w2) / 2;

        switch (selectedOption)
        {
        case Option::Telemetry:
            lcd.drawBox(6, y1 - 10, 116, 12); // плашка под 1-й строкой
            lcd.setDrawColor(0);              // текст "вычитается" (белый на черном)
            lcd.drawStr(x1, y1, item1);
            lcd.setDrawColor(1);
            lcd.drawStr(x2, y2, item2);
            break;
        case Option::Settings:
            lcd.drawStr(x1, y1, item1);
            lcd.drawBox(6, y2 - 10, 116, 12); // плашка под 2-й строкой
            lcd.setDrawColor(0);
            lcd.drawStr(x2, y2, item2);
            lcd.setDrawColor(1);

        default:
            throw std::runtime_error("Invalid option selected");
        }
        lcd.sendBuffer();
    };

    void handleInput(Input input) override
    {
        switch (input)
        {
        case Input::Up:
            selectedOption = static_cast<Option>((selectedOption - 1 + optionsSize) % optionsSize);
            break;
        case Input::Down:
            selectedOption = static_cast<Option>((selectedOption + 1) % optionsSize);
            break;
        case Input::Select:
            changeScreen();
            break;
        case Input::Back:
            returnToPreviousScreen();
            break;
        default:
            throw std::runtime_error("Invalid input");
        }
    };

    Screen &changeScreen() override
    {
        switch (selectedOption)
        {
        case Option::Telemetry:
            return telemetryScreen;
        case Option::Settings:
            return settingsScreen;
        default:
            throw std::runtime_error("Invalid option selected");
        }
    };

    Screen &returnToPreviousScreen() override
    {
        return *this;
    };
};
