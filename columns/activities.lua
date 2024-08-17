local ColumKey = "activities"
local Column = GreatVaultAddon:NewModule("GREATVAULTLIST_COLUMNS_" .. ColumKey, GREATVAULTLIST_COLUMNS)
local L, _ = GreatVaultAddon:GetLibs()


local DIFFICULTY_NAMES = {
	[DifficultyUtil.ID.DungeonHeroic] = "HC",
	[DifficultyUtil.ID.DungeonTimewalker] = "TW",
	[DifficultyUtil.ID.DungeonMythic] = "M",
}


Column.key = ColumKey
Column.config = {
    ["index"] = 7,
    ["header"] =  { key = ColumKey, text = L[ColumKey], width = 40, canSort = false, dataType = "string", order = "DESC", offset = 20, align = "center"},
    ["subCols"] = 3,
    ["sort"] = {
        ["key"] = ColumKey,
        ["store"] = "averageItemLevel",
    },
    ['emptyStr'] = {
        "0/1",
        "0/4",
        "0/8"
    },
    ["store"] = function(characterInfo)
        characterInfo.activities = C_WeeklyRewards.GetActivities(Enum.WeeklyRewardChestThresholdType.Activities)
        return characterInfo
    end,
    ["refresh"] = function(line, data, idx)
        local activity = _.get(data, {ColumKey, idx})
        local text = nil -- set default
        
        if activity.progress >= activity.threshold then
            text =  GREEN_FONT_COLOR_CODE 
                    .. 
                    (
                        DIFFICULTY_NAMES[activity.activityTierID] 
                        or 
                        (" +" .. activity.level .. " ")
                    )
                    .. 
                    FONT_COLOR_CODE_CLOSE
        elseif activity.progress > 0 then
            text = activity.progress .. "/" .. activity.threshold
        end

      

        line[ColumKey .. idx].text = text
        return line
    end
}