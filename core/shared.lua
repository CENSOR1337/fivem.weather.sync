local is_server = IsDuplicityVersion()

TIMESYNC_ENUM = {
    TIME_OFFSET_ROUND = 1,
    TIME_OFFSET_DAY = 2,
    IS_TIME_FREEZED = 3,
}

TIMESYNC_INFO = is_server and {
    [TIMESYNC_ENUM.TIME_OFFSET_ROUND] = 0,
    [TIMESYNC_ENUM.TIME_OFFSET_DAY] = 0,
    [TIMESYNC_ENUM.IS_TIME_FREEZED] = false,
}

if (is_server) then
    function UpdateGlobalState()
        if not (is_server) then return end

        GlobalState.TIMESYNC_INFO = TIMESYNC_INFO
    end

    -- reset global state
    UpdateGlobalState()
else
    TIMESYNC_INFO = GlobalState.TIMESYNC_INFO

    AddStateBagChangeHandler("TIMESYNC_INFO", "global", function(bag, key, value)
        if (key == "TIMESYNC_INFO") then
            TIMESYNC_INFO = value
        end
    end)
end
