local math_floor = math.floor
local Wait = Wait
local HasNetworkTimeStarted = HasNetworkTimeStarted
local GetNetworkTime = GetNetworkTime
local NetworkOverrideClockTime = NetworkOverrideClockTime
local ClearOverrideWeather = ClearOverrideWeather
local ClearWeatherTypePersist = ClearWeatherTypePersist
local SetWeatherTypePersist = SetWeatherTypePersist
local SetWeatherTypeNow = SetWeatherTypeNow
local SetWeatherTypeNowPersist = SetWeatherTypeNowPersist
local SetWeatherTypeOvertimePersist = SetWeatherTypeOvertimePersist

local GAME_DAY_IN_MS <const> = config.gameDayInSec * 1000
local WEATHER_INTERVAL_IN_MS <const> = config.weatherIntervalInSec * 1000
local WEATHER_MAX_INDEX <const> = #config.availableWeathers
local WEATHER_INTERPOLATION_SPEED <const> = config.weatherInterpolationSpeed + 0.0

assert(GAME_DAY_IN_MS > 0, "Invalid game day length")
assert(WEATHER_INTERVAL_IN_MS > 0, "Invalid weather interval")
assert(WEATHER_MAX_INDEX > 0, "No weather available")

local currentWeatherIndex = 1

local function changeWeather(weather)
    if (WEATHER_INTERPOLATION_SPEED <= 0) then
        ClearOverrideWeather()
        ClearWeatherTypePersist()
        SetWeatherTypePersist(weather)
        SetWeatherTypeNow(weather)
        SetWeatherTypeNowPersist(weather)
    else
        ClearOverrideWeather()
        SetWeatherTypeOvertimePersist(weather, WEATHER_INTERPOLATION_SPEED)
    end
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

    NetworkOverrideClockTime(hour, minute, second)

    local weatherProgress = netTime / (WEATHER_INTERVAL_IN_MS)
    local weatherIndex = math_floor(weatherProgress) % WEATHER_MAX_INDEX + 1

    local weather = config.availableWeathers[weatherIndex]

    if (currentWeatherIndex ~= weatherIndex) then
        currentWeatherIndex = weatherIndex
        changeWeather(weather)
    end
end

CreateThread(function()
    repeat
        Wait(0)
    until HasNetworkTimeStarted()

    while true do
        sync()
        Wait(4)
    end
end)
