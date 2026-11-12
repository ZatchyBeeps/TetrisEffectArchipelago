session = {}
local base_data = {
    ["server"] = "archipelago.gg",
    ["port"] = "38281",
    ["slot"] = "TetrisPlayer",
    ["password"] = "",
    ["seed"] = "",
    ["stages_stats"] = {}, -- [0] = {["completed"] = false, ["last_rank"] = 0}
    ["modes_stats"] = {}, -- [0] = {["completed"] = false, ["last_rank"] = 0}
}
local initialized = false


---@return {[string]: any}
function ReadAPSave()
    savefile = io.open("ue4ss\\ap_savedata.txt", "r")
    if not savefile then session = base_data return base_data end
    local ses_data = base_data
    ses_data["server"] = savefile:read("l")
    ses_data["port"] = savefile:read("l")
    ses_data["slot"] = savefile:read("l")
    ses_data["password"] = savefile:read("l")
    ses_data["seed"] = savefile:read("l")
    local reached_end = false
    local level_stats = {}
    while not reached_end do
        local firstread = savefile:read("l")
        if firstread == "end_stages" then
            reached_end = true
        else
            level_stats[tonumber(savefile:read("l"))] = {["completed"] = savefile:read("l") == "true", ["last_rank"] = tonumber(savefile:read("l"))}
        end
    end
    ses_data["stages_stats"] = level_stats
    reached_end = false
    level_stats = {}
    while not reached_end do
        local firstread = savefile:read("l")
        if firstread == "end_modes" then
            reached_end = true
        else
            level_stats[tonumber(savefile:read("l"))] = {["completed"] = savefile:read("l") == "true", ["last_rank"] = tonumber(savefile:read("l"))}
        end
    end
    ses_data["modes_stats"] = level_stats
    session = ses_data
    savefile:close()
    return ses_data
end

-- This method should be called if the port has been changed from last session.
function VerifySession(player, seed)
    if session["slot"] ~= player or session["seed"] ~= seed then
        return false
    end
    return true
end

function SaveConnectionInfo(server, port, slot, password)
    session["server"] = server
    session["port"] = port
    session["slot"] = slot
    session["password"] = password
    
end

function SaveData()
    local data_string = string.format("%s\n%s\n%s\n%s\n%s\n%s\n%s",
    session["server"],
    session["port"],
    session["slot"],
    session["password"],
    session["seed"],
    ObtainLevelString(session["stages_stats"]) .. "end_stages",
    ObtainLevelString(session["modes_stats"]) .. "end_modes"
)
    savefile = io.open("ue4ss\\ap_savedata.txt", "w")
    savefile:write(data_string)
    savefile:close()
end

function SaveLevelStats(stage_id, is_completed, last_rank, is_effect)
    if not is_effect then
        session["stages_stats"][stage_id] = {["completed"] = is_completed, ["last_rank"] = last_rank}
    else
        session["modes_stats"][stage_id] = {["completed"] = is_completed, ["last_rank"] = last_rank}
    end
end

function ObtainLevelString(level_table)
    local level_data = ""
    for level, stats in pairs(level_table) do
        level_data = level_data .. "\n" .. tostring(level)
        for _, value in pairs(stats) do
            level_data = level_data .. "\n" .. tostring(level)
        end
    end
    --level_data = level_data .. "\n"
    return level_data
end

