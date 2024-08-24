local ColumKey = "class"
local Column = GreatVaultList:NewModule(ColumKey, GREATVAULTLIST_COLUMNS)
local L, _ = GreatVaultList:GetLibs()

local CONST_SCROLL_LINE_HEIGHT = 20
Column.key = ColumKey
Column.config = {
    ["index"] = 1,
    ["width"] = 30,
    ["xpadding"] = 0, 
    ["ypadding"] = 0, 
    ["header"] = {key = ColumKey, text = "", width = 30, canSort = true, dataType = "string", order = "DESC", offset = 0, xpadding = 0, ypadding = 0 },
    ["sort"] = {
        ["key"] = ColumKey,
        ["store"] = ColumKey,
    },
    ["populate"] = function(self, class)
        if type(class) ~= "string" then return nil end
        local icon = CLASS_ICON_TCOORDS[class] or CLASS_ICON_TCOORDS["PALADIN"]
        local L, R, T, B = unpack(icon)
        return CreateTextureMarkup("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES", 1024,1024, 20, 20, L+0.02, R-0.02, T+0.02, B-0.02)
    end

}