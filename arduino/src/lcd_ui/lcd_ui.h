#include <stdexcept>

enum Input
{
    Up,
    Down,
    Select,
    Back
};

class Screen
{
public:
    virtual void render() = 0;
    virtual void handleInput(Input input) = 0;
    virtual Screen &changeScreen() = 0;
    virtual Screen &returnToPreviousScreen() = 0;
};

class TelemetryScreen : public Screen
{
    Screen &mainMenuScreen;

public:
    TelemetryScreen(Screen &mainMenuScreen) : mainMenuScreen(mainMenuScreen) {};

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

class SettingsScreen : public Screen
{
    Screen &mainMenuScreen;

public:
    SettingsScreen(Screen &mainMenuScreen) : mainMenuScreen(mainMenuScreen) {};

    // TODO Implement rendering logic for the settings screen
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

class MainMenuScreen : public Screen
{
public:
    TelemetryScreen telemetryScreen;
    SettingsScreen settingsScreen;

    MainMenuScreen() : telemetryScreen(*this), settingsScreen(*this) {}

    enum Options
    {
        Telemetry,
        Settings
    } selectedOption = Options::Telemetry;

    // TODO: Implement rendering logic for the main menu screen
    void render() override {
    };

    void handleInput(Input input) override
    {
        switch (input)
        {
        case Input::Up:
            selectedOption = static_cast<Options>((selectedOption - 1 + 2) % 2);
            break;
        case Input::Down:
            selectedOption = static_cast<Options>((selectedOption + 1) % 2);
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
        case Options::Telemetry:
            return telemetryScreen;
        case Options::Settings:
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