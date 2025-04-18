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

    local now_ms = TIMESYNC_INFO[TIMESYNC_ENUM.IS_TIME_FREEZED] and 0 or GetGameTimer()
    local day_progress = (now_ms % GAME_DAY_IN_MS) / GAME_DAY_IN_MS
    local ms_until_midnight = math.clamp(1.0 - day_progress, 0.0, 1.0) * 86400000
    local ms_midnight_to_settime = (hour * 3600 + minute * 60) * 1000

    TIMESYNC_INFO[TIMESYNC_ENUM.TIME_OFFSET_ROUND] = ms_until_midnight
    TIMESYNC_INFO[TIMESYNC_ENUM.TIME_OFFSET_DAY] = ms_midnight_to_settime

    UpdateGlobalState()
end

local function toggle_time_freeze(new_state)
    if (TIMESYNC_INFO[TIMESYNC_ENUM.IS_TIME_FREEZED] == new_state) then return end

    local net_time = TIMESYNC_INFO[TIMESYNC_ENUM.IS_TIME_FREEZED] and 0 or GetGameTimer()

    local day_progress = (net_time % GAME_DAY_IN_MS) / GAME_DAY_IN_MS

    local ms_offset = TIMESYNC_INFO[TIMESYNC_ENUM.TIME_OFFSET_ROUND] or 0
    ms_offset += TIMESYNC_INFO[TIMESYNC_ENUM.TIME_OFFSET_DAY] or 0

    local ms_of_day = day_progress * 86400000 + ms_offset
    local sec_of_day = ms_of_day / 1000
    local min_of_day = sec_of_day / 60
    local hour_of_day = min_of_day / 60

    local clock_hour = math.floor(hour_of_day) % 24
    local clock_minute = math.floor(min_of_day) % 60

    TIMESYNC_INFO[TIMESYNC_ENUM.IS_TIME_FREEZED] = not TIMESYNC_INFO[TIMESYNC_ENUM.IS_TIME_FREEZED]

    set_time(clock_hour, clock_minute) -- global state being updated in set_time
end

local function command_time_set(src, args, raw_commands)
    if not (has_authority(src)) then return end

    local hour = tonumber(args[1])
    local minute = tonumber(args[2]) or 0

    set_time(hour, minute)
end

local function command_time_freeze(src, args, raw_commands)
    if not (has_authority(src)) then return end

    local new_state = args[1] == "true" or args[1] == "1" or args[1] == "yes" or args[1] == "on" or args[1] == "enable"

    toggle_time_freeze(new_state)
end

RegisterCommand("time.set", command_time_set, false)
RegisterCommand("time.freeze", command_time_freeze, false)
