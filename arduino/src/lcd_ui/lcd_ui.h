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

public:
    TelemetryScreen(U8G2 &lcd, Screen &mainMenuScreen) : Screen(lcd), mainMenuScreen(mainMenuScreen) {};

    // TODO Implement rendering logic for the telemetry screen
    void render() override {};

    void handleInput(Input input) override
    {
        switch (input)
        {
        case Input::Up:
        case Input::Down:
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
        case Input::Down:
            selectedOption = static_cast<Option>((selectedOption + 1) % optionsSize);
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
