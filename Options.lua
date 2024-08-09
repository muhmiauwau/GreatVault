local GreatVaultAddon = LibStub("AceAddon-3.0"):GetAddon("GreatVaultList")
local L, _ = GreatVaultAddon:GetLibs()


GreatVaultAddonOptions = {}


function GreatVaultAddonOptions:createOptions()
    


    local loadedColumms = _.filter(GreatVaultAddon.db.global.columns, function (col)
        return (col.loaded == true)
    end)



    local columnLen = _.size(loadedColumms)


    local heightSize = (columnLen * 23) + 65

    local optionsFrame = DetailsFramework:CreateSimplePanel(UIParent, 600, heightSize, L["opt_windowname"], "GreatVaultAddonOptionsPanel")
    optionsFrame:SetFrameStrata("DIALOG")
    optionsFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    optionsFrame:Show()

    local scaleBar = DetailsFramework:CreateScaleBar(optionsFrame, GreatVaultAddon.db.global.greatvault_frame)
    optionsFrame:SetScale(GreatVaultAddon.db.global.greatvault_frame.scale)

    local bUseSolidColor = true
    DetailsFramework:ApplyStandardBackdrop(optionsFrame, bUseSolidColor)

    local options_text_template = DetailsFramework:GetTemplate("font", "OPTIONS_FONT_TEMPLATE")
    local options_dropdown_template = DetailsFramework:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE")
    local options_switch_template = DetailsFramework:GetTemplate("switch", "OPTIONS_CHECKBOX_TEMPLATE")
    local options_slider_template = DetailsFramework:GetTemplate("slider", "OPTIONS_SLIDER_TEMPLATE")
    local options_button_template = DetailsFramework:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE")
    local subSectionTitleTextTemplate = DetailsFramework:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
    
    local reloadSettings = function()
        C_UI.Reload()
    end

    local reloadSettingsButton = DetailsFramework:CreateButton(optionsFrame, reloadSettings, 130, 20, L["Reload UI"])
    reloadSettingsButton:SetPoint("bottomleft", optionsFrame, "bottomleft", 15, 15)
    reloadSettingsButton:SetTemplate(options_button_template)
    
    local optionsTable = {
        {type = "label", get = function() return L["opt_option"] end},
        {
            type = "range",
            get = function()
                return GreatVaultAddon.db.global.greatvault_frame.lines
            end,
            set = function(self, fixedparam, value)
                GreatVaultAddon.db.global.greatvault_frame.lines = value
            end,
            min = 1,
            max = 50,
            step = 1,
            name = L["opt_lines_name"],
            desc = L["opt_lines_desc"],
        },
    }

    --build the menu
    optionsTable.always_boxfirst = true

    local startX = 15
    local startY = -32
    DetailsFramework:BuildMenu(optionsFrame, optionsTable, startX, startY, heightSize, false, options_text_template, options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template)




    sectionFrame = optionsFrame
    sectionFrame.AutoHideOptions = {}


    local header1Label = _G.DetailsFramework:CreateLabel(sectionFrame, L["opt_column"])
    local header3Label = _G.DetailsFramework:CreateLabel(sectionFrame,L["opt_enabled"])
    local header4Label = _G.DetailsFramework:CreateLabel(sectionFrame, L["opt_position"])

    
    local right_start_at = 250
    header1Label:SetPoint("topleft", sectionFrame, "topleft", right_start_at, startY)
    header3Label:SetPoint("topright", sectionFrame, "topleft", right_start_at + 160, startY)
    header4Label:SetPoint("topleft", sectionFrame, "topleft", right_start_at + 164, startY)

    
    local i = 0
    _.forEach(loadedColumms, function(column)
        i = i + 1

        local key = column.key

        local line = _G.CreateFrame("frame", nil, sectionFrame,"BackdropTemplate")
        line:SetSize(302, 22)
        line:SetPoint("topleft", sectionFrame, "topleft", right_start_at, startY + ((i) * -23) + 4)
        DetailsFramework:ApplyStandardBackdrop(line)

        local contextLabel = DetailsFramework:CreateLabel(line, L[key])
        contextLabel:SetPoint("left", line, "left", 2, 0)
        contextLabel.textsize = 10


        local enabledCheckbox = DetailsFramework:NewSwitch(line, nil, nil, nil, 20, 20, nil, nil, false, nil, nil, nil, nil, options_switch_template)
        enabledCheckbox:SetPoint("left", line, "left", 140, 1)
        enabledCheckbox:SetAsCheckBox()
        enabledCheckbox:SetFixedParameter(key)
        enabledCheckbox:SetValue(GreatVaultAddon.db.global.columns[key].active)
        enabledCheckbox.OnSwitch = function(self, contextId, value) 
            GreatVaultAddon.db.global.columns[contextId].active = value
        end


        local positionSlider = DetailsFramework:CreateSlider(line, 138, 20, 1, columnLen, 1, columnLen, false, nil, nil, nil, options_slider_template)
        positionSlider:SetPoint("left", line, "left", 164, 0)
        positionSlider:SetFixedParameter(key)
        positionSlider:SetValue(GreatVaultAddon.db.global.columns[key].position)
        positionSlider:SetHook("OnValueChanged", function(self, contextId, value)
            GreatVaultAddon.db.global.columns[contextId].position = value
        end)

        positionSlider.thumb:SetWidth(32)
        
    end)



end



function GreatVaultAddonOptions:toggle()


    if GreatVaultAddonOptionsPanel then
        GreatVaultAddonOptionsPanel:SetShown(not GreatVaultAddonOptionsPanel:IsShown()) 
    else
        self:createOptions()
    end

    
end
