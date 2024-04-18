rawset(_ENV, "config", {}) -- stop linter from bitching

-- how long in game day in seconds
config.gameDayInSec = 2880 -- 48 minutes, same as GTA Online

-- how often weather will change
config.weatherIntervalInSec = 3600 -- 1 hours

-- how fast weather will change, 0 is instantly
config.weatherInterpolationSpeedInMs = 128.0

-- weather will change in order of this list
config.availableWeathers = {
    "CLEAR",
    "EXTRASUNNY",
    "CLOUDS",
    "OVERCAST",
    "RAIN",
    "CLEARING",
    "THUNDER",
    "SMOG",
    "FOGGY",
    "XMAS",
    "SNOW",
    "SNOWLIGHT",
    "BLIZZARD",
    "HALLOWEEN",
    "NEUTRAL",
}
