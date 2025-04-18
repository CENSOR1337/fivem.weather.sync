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

assert(GAME_DAY_IN_MS > 0, "Invalid game day length")
assert(WEATHER_INTERVAL_IN_MS > 0, "Invalid weather interval")
assert(WEATHER_MAX_INDEX > 0, "No weather available")

SetWeatherOwnedByNetwork(false)
ClearWeatherTypePersist()

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

    NetworkOverrideClockTime(hour, minute, second)

    local weatherProgress = netTime / (WEATHER_INTERVAL_IN_MS)
    local weatherIndex = math_floor(weatherProgress) % WEATHER_MAX_INDEX + 1

    local currentWeather = config.availableWeathers[weatherIndex]
    local nextWeather = config.availableWeathers[(weatherIndex % WEATHER_MAX_INDEX) + 1]

    local timeSinceLastWeatherChange = netTime % WEATHER_INTERVAL_IN_MS
    local weatherTimeAlpha = roundDecimal(timeSinceLastWeatherChange / WEATHER_INTERPOLATION_SPEED, 2)
    weatherTimeAlpha = numClamp(weatherTimeAlpha, 0.0, 1.0)

    SetWeatherTypeTransition(currentWeather, nextWeather, weatherTimeAlpha)
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


CreateThread(function(threadId)
    if not (config.debug) then return end

    while true do
        local hour = GetClockHours()
        local min = GetClockMinutes()
        local sec = GetClockSeconds()

        local text = string.format("%02d:%02d:%02d", hour, min, sec)
        local offset = vec(0.5, 0.025)
        local scale = 0.6
        local font = 6
        local color = { r = 255, g = 255, b = 255, a = 255 }
        local bCenter = true
        local align = 0
        SetTextFont(font)
        SetTextScale(1, scale)
        SetTextWrap(0.0, 1.0)
        SetTextCentre(bCenter)
        SetTextColour(color.r, color.g, color.b, color.a)
        SetTextJustification(align)
        SetTextEdge(1, 0, 0, 0, 255)
        SetTextOutline()
        SetTextDropShadow()
        BeginTextCommandDisplayText("STRING")
        AddTextComponentSubstringPlayerName(text)
        EndTextCommandDisplayText(offset.x, offset.y)
        Wait(0)
    end
end)
