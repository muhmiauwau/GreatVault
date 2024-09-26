local ColumKey = "character"
local Column = GreatVaultList:NewModule(ColumKey, GREATVAULTLIST_COLUMNS)
local L, _ = GreatVaultList:GetLibs()

Column.key = ColumKey
Column.DBkey = "name"
Column.config = {
    ["index"] = 2,
    ["width"] = 100,
    ["autoWidth"] = true,
    ["header"] = {key = ColumKey, text = L[ColumKey], canSort = true},
    ["demo"] = function(idx)
        local names = {"Jesternar", "Mishenani", "Martiners", "Mydraciea", "Monzorust", "Ysedbelly", "Connerrig", "Trauddled", "Groldrold", "Shillenton", "Ravenf", "Reginotta", "Groldrold"};
        return names[idx]
    end,
    ["store"] = function(characterInfo)
        local _, className = UnitClass("player")
        characterInfo.name = UnitName("player")
        characterInfo.class = className
        characterInfo.realm = GetRealmName()
        characterInfo.level = UnitLevel("player")

        return characterInfo
    end,

}