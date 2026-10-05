-- See TetrisEffect/Content/Tables/ResultRankReserveTable2.uasset
-- Theres no other way to asynchronously obtain these other than manually
-- I was thinking of dummying the datatable with the blueprint helper on runtime to extract the values 
-- but idk this was honestly maybe easier than dummying other 4 neccessary struct blueprints to properly dummy the row data
---@type { [integer]: {[string]: table } }
AreaRankTables = {
    [1] = {
        ["D"] = {1000, 1000, 1000},
        ["C"] = {9000, 10800, 14400},
        ["B"] = {19200, 21600, 28800},
        ["A"] = {27600, 31200, 42000},
        ["S"] = {41100, 52200, 69000},
        ["SS"] = {50100, 61200, 81000}
    },
    [2] = {
        ["D"] = {1000, 1000, 1000},
        ["C"] = {12000, 14400, 19200},
        ["B"] = {25600, 28800, 38400},
        ["A"] = {36800, 41600, 56000},
        ["S"] = {54800, 69600, 92000},
        ["SS"] = {66800, 81600, 10800}
    },
    [3] = {
        ["D"] = {1000, 1000, 1000},
        ["C"] = {12000, 14400, 19200},
        ["B"] = {25600, 28800, 38400},
        ["A"] = {36800, 41600, 56000},
        ["S"] = {54800, 69600, 92000},
        ["SS"] = {66800, 81600, 10800}
    },
    [4] = {
        ["D"] = {1000, 1000, 1000},
        ["C"] = {15000, 18000, 24000},
        ["B"] = {32000, 36000, 48000},
        ["A"] = {46000, 52000, 70000},
        ["S"] = {68500, 87000, 115000},
        ["SS"] = {83500, 102000, 135000}
    },
    [5] = {
        ["D"] = {1000, 1000, 1000},
        ["C"] = {15000, 18000, 24000},
        ["B"] = {32000, 36000, 48000},
        ["A"] = {46000, 52000, 70000},
        ["S"] = {68500, 87000, 115000},
        ["SS"] = {83500, 102000, 135000}
    },
    [6] = {
        ["D"] = {1000, 1000, 1000},
        ["C"] = {15000, 18000, 24000},
        ["B"] = {32000, 36000, 48000},
        ["A"] = {46000, 52000, 70000},
        ["S"] = {68500, 87000, 115000},
        ["SS"] = {83500, 102000, 135000}
    }
}

---@param score integer Current score of player
---@param area integer Level index
---@param difficulty integer What difficulty is the player on? (1: easy, 2: normal, 3: hard)
---@return string[]
function RequestAreaRank(score, area, difficulty)
    LevelTable = RankTables[area]
    ResultRanks = {"E"}
    for rank, score_requirements in pairs(LevelTable) do
        if score_requirements[difficulty] < score then
            table.insert(ResultRanks, rank)
        end
    end
    return ResultRanks
end