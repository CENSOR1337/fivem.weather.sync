local math_floor = math.floor
local Wait = Wait
local HasNetworkTimeStarted = HasNetworkTimeStarted
local GetNetworkTime = GetNetworkTime
local NetworkOverrideClockTime = NetworkOverrideClockTime
local ClearWeatherTypePersist = ClearWeatherTypePersist
local SetWeatherTypeTransition = SetWeatherTypeTransition

local GAME_DAY_IN_MS <const> = config.gameDayInSec * 1000
local WEATHER_INTERVAL_IN_MS <const> = config.weatherIntervalInSec * 1000
local WEATHER_MAX_INDEX <const> = #config.availableWeathers
local WEATHER_INTERPOLATION_SPEED <const> = math.min(config.weatherInterpolationSpeedInMs, WEATHER_INTERVAL_IN_MS)
local LOOP_INTERVAL <const> = math.max(math.min(config.gameDayInSec, config.weatherIntervalInSec) * 0.05, 4)
local GAME_WEATHERS <const> = {
    CLEAR = 0,
    EXTRASUNNY = 1,
    CLOUDS = 2,
    OVERCAST = 3,
    RAIN = 4,
    CLEARING = 5,
    THUNDER = 6,
    SMOG = 7,
    FOGGY = 8,
    XMAS = 9,
    SNOW = 10,
    SNOWLIGHT = 11,
    BLIZZARD = 12,
    HALLOWEEN = 13,
    NEUTRAL = 14,
}

assert(GAME_DAY_IN_MS > 0, "Invalid game day length")
assert(WEATHER_INTERVAL_IN_MS > 0, "Invalid weather interval")
assert(WEATHER_MAX_INDEX > 0, "No weather available")

SetWeatherOwnedByNetwork(false)
ClearWeatherTypePersist()

local override_sync_time_info = {
    enabled = false,
    hour = 0,
    min = 0,
}

local override_sync_weather_info = {
    enabled = false,
    name = "EXTRASUNNY",
}

local function roundDecimal(num, places)
    local mult = 10 ^ places
    return math.floor(num * mult + 0.5) / mult
end

local function numClamp(num, min, max)
    return math.min(math.max(num, min), max)
end

local function sync()
    local netTime = GetNetworkTime()

    local dayProgress = netTime % (GAME_DAY_IN_MS)

    local hourAlpha = dayProgress / GAME_DAY_IN_MS
    local hour = math_floor(hourAlpha * 24)

    local minuteAlpha = (hourAlpha * 24) % 1
    local minute = math_floor(minuteAlpha * 60)

    local secondAlpha = (minuteAlpha * 60) % 1
    local second = math_floor(secondAlpha * 60)

    if (override_sync_time_info.enabled) then
        hour = override_sync_time_info.hour
        minute = override_sync_time_info.min
    end

    NetworkOverrideClockTime(hour, minute, second)

    local weatherProgress = netTime / (WEATHER_INTERVAL_IN_MS)
    local weatherIndex = math_floor(weatherProgress) % WEATHER_MAX_INDEX + 1

    local currentWeather = config.availableWeathers[weatherIndex]
    local nextWeather = config.availableWeathers[(weatherIndex % WEATHER_MAX_INDEX) + 1]

    local timeSinceLastWeatherChange = netTime % WEATHER_INTERVAL_IN_MS
    local weatherTimeAlpha = roundDecimal(timeSinceLastWeatherChange / WEATHER_INTERPOLATION_SPEED, 2)
    weatherTimeAlpha = numClamp(weatherTimeAlpha, 0.0, 1.0)

    if (override_sync_weather_info.enabled) then
        currentWeather = override_sync_weather_info.name
        nextWeather = override_sync_weather_info.name
        weatherTimeAlpha = 1.0
    end

    SetWeatherTypeTransition(currentWeather, nextWeather, weatherTimeAlpha)
end

local function override_sync_time(hour, min)
    assert(hour >= 0 and hour < 24, "Hour must be between 0 and 23")
    assert(min >= 0 and min < 60, "Minute must be between 0 and 59")

    override_sync_time_info.enabled = true
    override_sync_time_info.hour = hour
    override_sync_time_info.min = min
end

local function override_sync_weather(weather_name)
    assert(GAME_WEATHERS[weather_name], ("%s is not a valid weather type"):format(weather_name))

    override_sync_weather_info.enabled = true
    override_sync_weather_info.name = weather_name
end

local function clear_sync_time_override()
    override_sync_time_info.enabled = false
end

local function clear_sync_weather_override()
    override_sync_weather_info.enabled = false
end

CreateThread(function()
    repeat
        Wait(0)
    until HasNetworkTimeStarted()

    while true do
        sync()
        Wait(LOOP_INTERVAL)
    end
end)

exports("override_sync_time", override_sync_time)
exports("override_sync_weather", override_sync_weather)
exports("clear_sync_time_override", clear_sync_time_override)
exports("clear_sync_weather_override", clear_sync_weather_override)

-- bridges compatibility
local bridge = {}

function bridge.cd_easytime_pause_sync(boolean, time)
    if (boolean == true) then
        time = time or 12
        override_sync_time(time, 0)
        override_sync_weather("EXTRASUNNY")
    else
        clear_sync_time_override()
        clear_sync_weather_override()
    end
end

function bridge.vsync_toggle(boolean)
    bridge.cd_easytime_pause_sync(boolean, 12)
end

RegisterNetEvent("cd_easytime:PauseSync", bridge.cd_easytime_pause_sync)
RegisterNetEvent("vSync:toggle", bridge.vsync_toggle)
