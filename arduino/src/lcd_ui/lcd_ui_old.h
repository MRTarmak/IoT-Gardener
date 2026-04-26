#pragma once
#include <stdexcept>
#include <memory>
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
    virtual std::shared_ptr<Screen> changeScreen() = 0;
    virtual std::weak_ptr<Screen> returnToBackScreen() = 0;
    virtual ~Screen() = default;

    void noScrollRender(const uint8_t itemsSize, const char *items[], int selectedOption)
    {
        // Validation
        if (itemsSize == 0)
            throw std::runtime_error("No items to display");
        if (selectedOption < 0)
            throw std::runtime_error("Invalid option selected");
        if (selectedOption >= itemsSize)
            throw std::runtime_error("Invalid option selected");

        lcd.clearBuffer();
        lcd.setFont(u8g2_font_6x10_tf);

        // Outter frame
        lcd.drawFrame(0, 0, 128, 64);

        // Text parameters
        const int lineH = 12; // line height
        const int blockH = lineH * 3;
        const int topY = (64 - blockH) / 2; // top of block of 3 lines

        int x, y, w;
        for (int i = 0; i < itemsSize; i++)
        {
            // Baseline
            y = topY + 10 + lineH * i;

            // Centering on X
            w = lcd.getStrWidth(items[i]);
            x = (128 - w) / 2;

            // Rendering
            if (i == selectedOption)
            {
                lcd.drawBox(6, y - 10, 116, 12);
                lcd.setDrawColor(0);
                lcd.drawStr(x, y, items[i]);
                lcd.setDrawColor(1);
            }
            else
            {
                lcd.drawStr(x, y, items[i]);
            }
        }

        lcd.sendBuffer();
    }
};

class TelemetryScreen : public Screen
{
    std::weak_ptr<Screen> mainMenuScreen;

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
    TelemetryScreen(U8G2 &lcd) : Screen(lcd) {};

    void setMainMenuScreen(std::weak_ptr<Screen> mainMenuScreen)
    {
        this->mainMenuScreen = mainMenuScreen;
    }

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

        // Validation
        if (itemsSize == 0)
            throw std::runtime_error("No items to display");
        if (selectedOption < 0)
            throw std::runtime_error("Invalid option selected");
        if (selectedOption >= itemsSize)
            throw std::runtime_error("Invalid option selected");

        lcd.clearBuffer();
        lcd.setFont(u8g2_font_6x10_tf);

        // Outter frame
        lcd.drawFrame(0, 0, 128, 64);

        // Text parameters
        const int lineH = 12;                // line height
        const int maxLines = 5;              // display 5 lines, 6th is hidden
        const int blockH = lineH * maxLines; // height of block of 5 lines
        const int topY = (64 - blockH) / 2;  // top of block of 3 lines
        
        // Rendering
        int x, y, w;
        for (int i = 0; i < itemsSize; i++)
        {
            // Centering on X
            w = lcd.getStrWidth(items[i]);
            x = (128 - w) / 2;

            // Rendering
            if (!isScrolled)
            {
                if (i == 5)
                    continue; // 6-я строка скрыта

                y = topY + 10 + lineH * i; // baseline
                if (i == static_cast<int>(selectedOption))
                {
                    lcd.drawBox(6, y - 10, 116, 12);
                    lcd.setDrawColor(0);
                    lcd.drawStr(x, y, items[i]);
                    lcd.setDrawColor(1);
                }
                else
                {
                    lcd.drawStr(x, y, items[i]);
                }
            }
            else
            {
                if (i == 0)
                    continue; // 1-я строка скрыта

                y = topY + 10 + lineH * (i - 1); // scrolled baseline
                if (i == static_cast<int>(selectedOption))
                {
                    lcd.drawBox(6, y - 10, 116, 12);
                    lcd.setDrawColor(0);
                    lcd.drawStr(x, y, items[i]);
                    lcd.setDrawColor(1);
                }
                else
                {
                    lcd.drawStr(x, y, items[i]);
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
            returnToBackScreen();
            break;
        default:
            throw std::runtime_error("Invalid input");
        }
    };

    std::shared_ptr<Screen> changeScreen() override
    {
        return nullptr;
    };

    std::weak_ptr<Screen> returnToBackScreen() override
    {
        return mainMenuScreen;
    };
};

// TODO добавить получение текущего режима и сети
class SettingsScreen : public Screen
{
    std::weak_ptr<Screen> mainMenuScreen;

    enum Option
    {
        Mode,
        CurrentNetwork,
        ResetNetwork
    } selectedOption = Option::Mode;

    const uint8_t optionsSize = 3;

public:
    SettingsScreen(U8G2 &lcd) : Screen(lcd) {};

    void setMainMenuScreen(std::weak_ptr<Screen> mainMenuScreen)
    {
        this->mainMenuScreen = mainMenuScreen;
    }

    void render() override
    {
        const uint8_t itemsSize = 3;
        const char *items[itemsSize] = {
            "Mode: ",
            "Current Network: ",
            "Reset Network"};

        noScrollRender(itemsSize, items, static_cast<int>(selectedOption));
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
            returnToBackScreen();
            break;
        default:
            throw std::runtime_error("Invalid input");
        }
    };

    std::shared_ptr<Screen> changeScreen() override
    {
        return nullptr;
    };

    std::weak_ptr<Screen> returnToBackScreen() override
    {
        return mainMenuScreen;
    };
};

class MainMenuScreen : public Screen
{
    std::shared_ptr<Screen> telemetryScreen;
    std::shared_ptr<Screen> settingsScreen;

    enum Option
    {
        Telemetry,
        Settings
    } selectedOption = Option::Telemetry;

    const uint8_t optionsSize = 2;

public:
    MainMenuScreen(U8G2 &lcd) : Screen(lcd) {}

    void setTelemetryScreen(std::shared_ptr<Screen> telemetryScreen)
    {
        this->telemetryScreen = telemetryScreen;
    }

    void setSettingsScreen(std::shared_ptr<Screen> settingsScreen)
    {
        this->settingsScreen = settingsScreen;
    }

    void render() override
    {
        const uint8_t itemsSize = 2;
        const char *items[itemsSize] = {
            "Telemetry",
            "Settings"};

        noScrollRender(itemsSize, items, static_cast<int>(selectedOption));
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
            returnToBackScreen();
            break;
        default:
            throw std::runtime_error("Invalid input");
        }
    };

    std::shared_ptr<Screen> changeScreen() override
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

    std::weak_ptr<Screen> returnToBackScreen() override
    {
        return std::weak_ptr<Screen>();
    };
};

class LCDUI
{
    U8G2 &lcd;
    std::shared_ptr<Screen> mainMenuScreen;
    std::shared_ptr<Screen> telemetryScreen;
    std::shared_ptr<Screen> settingsScreen;

    std::shared_ptr<Screen> currentScreen;

public:
    explicit LCDUI(U8G2 &lcd) : lcd(lcd)
    {
        mainMenuScreen = std::make_shared<MainMenuScreen>(lcd);
        telemetryScreen = std::make_shared<TelemetryScreen>(lcd);
        settingsScreen = std::make_shared<SettingsScreen>(lcd);

        std::dynamic_pointer_cast<MainMenuScreen>(mainMenuScreen)->setTelemetryScreen(telemetryScreen);
        std::dynamic_pointer_cast<MainMenuScreen>(mainMenuScreen)->setSettingsScreen(settingsScreen);
        std::dynamic_pointer_cast<TelemetryScreen>(telemetryScreen)->setMainMenuScreen(mainMenuScreen);
        std::dynamic_pointer_cast<SettingsScreen>(settingsScreen)->setMainMenuScreen(mainMenuScreen);

        currentScreen = mainMenuScreen;
    }
};
