-- TODO: Implement a command that allow to set game time and weather
-- Is it even gonna happen i have no idea lmao

local GAME_DAY_IN_MS <const> = config.gameDayInSec * 1000

function math.clamp(val, lower, upper)                    -- credit overextended, https://love2d.org/forums/viewtopic.php?t=1856
    if lower > upper then lower, upper = upper, lower end -- swap if boundaries supplied the wrong way
    return math.max(lower, math.min(upper, val))
end

local function has_authority(src)
    if (src <= 0) then
        return true
    end

    return IsPlayerAceAllowed(src, "command")
end

local function set_time(hour, minute)
    if not (hour) or not (minute) then return end

    hour = math.clamp(hour, 0, 23)
    minute = math.clamp(minute, 0, 59)

    local now_ms = GetGameTimer()
    local day_progress = (now_ms % GAME_DAY_IN_MS) / GAME_DAY_IN_MS
    local ms_until_midnight = math.clamp(1.0 - day_progress, 0.0, 1.0) * 86400000
    local ms_midnight_to_settime = (hour * 3600 + minute * 60) * 1000

    TIMESYNC_INFO[TIMESYNC_ENUM.TIME_OFFSET_ROUND] = ms_until_midnight
    TIMESYNC_INFO[TIMESYNC_ENUM.TIME_OFFSET_DAY] = ms_midnight_to_settime

    UpdateGlobalState()
end

local function command_time_set(src, args, raw_commands)
    if not (has_authority(src)) then return end

    local hour = tonumber(args[1])
    local minute = tonumber(args[2]) or 0

    set_time(hour, minute)
end

RegisterCommand("time.set", command_time_set, false)
