---@diagnostic disable: deprecated
---@class GreatVaultAddon:AceAddon
GreatVaultAddon = LibStub("AceAddon-3.0"):NewAddon("GreatVaultList", "AceEvent-3.0");
local L = LibStub("AceLocale-3.0"):GetLocale("GreatVaultList")
local _ = LibStub("Lodash"):Get()

function GreatVaultAddon:GetLibs()
    return L, _
end 

local PlayerName = UnitName("player")


local playerConfig = nil
local sortConfig  = {}
local viewTypes = {}

--frame options
local CONST_WINDOW_WIDTH = 0
local CONST_SCROLL_LINE_HEIGHT = 20
local CONST_WINDOW_HEIGHT = 0

local backdrop_color = {.2, .2, .2, 0.2}
local backdrop_color_on_enter = {.8, .8, .8, 0.4}
local backdrop_color_inparty = {.5, .5, .8, 0.2}


local DIFFICULTY_NAMES = {
	[DifficultyUtil.ID.DungeonNormal] = "NHC",
	[DifficultyUtil.ID.DungeonHeroic] = "HC",
	[DifficultyUtil.ID.Raid10Normal] = "NHC",
	[DifficultyUtil.ID.Raid25Normal] = "NHC",
	[DifficultyUtil.ID.Raid10Heroic] = "HC",
	[DifficultyUtil.ID.Raid25Heroic] = "HC",
	[DifficultyUtil.ID.RaidLFR] = "LFR",
	[DifficultyUtil.ID.DungeonChallenge] = PLAYER_DIFFICULTY_MYTHIC_PLUS,
	[DifficultyUtil.ID.Raid40] = LEGACY_RAID_DIFFICULTY,
	[DifficultyUtil.ID.PrimaryRaidNormal] = "NHC",
	[DifficultyUtil.ID.PrimaryRaidHeroic] = "HC",
	[DifficultyUtil.ID.PrimaryRaidMythic] = "MTH",
	[DifficultyUtil.ID.PrimaryRaidLFR] = "LFR",
	[DifficultyUtil.ID.DungeonMythic] = PLAYER_DIFFICULTY6,
	[DifficultyUtil.ID.DungeonTimewalker] = PLAYER_DIFFICULTY_TIMEWALKER,
	[DifficultyUtil.ID.RaidTimewalker] = PLAYER_DIFFICULTY_TIMEWALKER,
}


--namespace
GreatVaultAddon.ScrollFrame = {}

local default_global_data = {
	global = {
		greatvault_frame = {
			scale = 1,
			position = {},
			lines = 12
		},
		characters = {},
		view = {
			raid = true,
			activities = true,
			pvp = false
		}
	}
}


local headerTable = {}
local headerTableConfig  = {}

local colConfig = {}

local function shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function GreatVaultAddon:addColumn(config)
	table.insert(headerTableConfig, config.key)
	table.insert(headerTable, config)
end


function GreatVaultAddon:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("GreatVaultListDB", default_global_data, true)
	GreatVaultAddon.db.global.columns = GreatVaultAddon.db.global.columns or {}

	CONST_WINDOW_HEIGHT = GreatVaultAddon.db.global.greatvault_frame.lines * CONST_SCROLL_LINE_HEIGHT + 70

	C_AddOns.LoadAddOn("Blizzard_WeeklyRewards");
	--WeeklyRewardExpirationWarningDialog:Hide()

	GreatVaultAddon:slashcommand()
end

function GreatVaultAddon:Initwindow()
	self:SetupColumns()
    GreatVaultAddon:createWindow()

	C_Timer.After(3, function() 
		GreatVaultAddon:SaveCharacterInfo(playerConfig)
	end)

	GreatVaultInfoFrame:Hide()


	
	
end

function GreatVaultAddon:slashcommand() 
	SLASH_GV1 = "/gv"
	SLASH_GV2 = "/greatvault"
	SlashCmdList["GV"] = function(msg)
        if GreatVaultInfoFrame:IsShown() then 
            GreatVaultInfoFrame:Hide()
        else
			
            GreatVaultInfoFrame:Show()
        end
	end 
end

function GreatVaultAddon:sortEntries(columnIndex, order)
    local data = GreatVaultAddon.ScrollFrame.ScollFrame:GetData()
	columnIndex = sortConfig[columnIndex]
	table.sort(data, function (k1, k2) 
		if order == "DESC" then
			return k1[columnIndex] < k2[columnIndex]
		else 
			return k1[columnIndex] > k2[columnIndex]
		end
	end)
	GreatVaultAddon.ScrollFrame.ScollFrame:SetData(data)
	GreatVaultAddon.ScrollFrame.ScollFrame:Refresh()
end 

function GreatVaultAddon:createWindow() 

	local f = DetailsFramework:CreateSimplePanel(UIParent, CONST_WINDOW_WIDTH, CONST_WINDOW_HEIGHT, L["addonName"], "GreatVaultInfoFrame")
	f:SetFrameStrata("HIGH")
	f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

	f:SetScript("OnMouseDown", nil)
	f:SetScript("OnMouseUp", nil)
	
	f:SetScript("OnShow", function()
		for _, value in pairs(colConfig) do
			if value["OnShow"] then 
				local fn = value["OnShow"]
				fn(self, value)
			end
		end
		GreatVaultAddon.ScrollFrame.ScollFrame:Refresh()
	end)


	local LibWindow = LibStub("LibWindow-1.1")
	LibWindow.RegisterConfig(f, GreatVaultAddon.db.global.greatvault_frame.position)
	LibWindow.MakeDraggable(f)
	LibWindow.RestorePosition(f)

	local scaleBar = DetailsFramework:CreateScaleBar(f, GreatVaultAddon.db.global.greatvault_frame)
	f:SetScale(GreatVaultAddon.db.global.greatvault_frame.scale)

	local statusBar = DetailsFramework:CreateStatusBar(f)
	statusBar.text = statusBar:CreateFontString(nil, "overlay", "GameFontNormal")
	statusBar.text:SetPoint("left", statusBar, "left", 5, 0)
	statusBar.text:SetText("By muhmiauwau | Built with Details! Framework")
	DetailsFramework:SetFontSize(statusBar.text, 11)
	DetailsFramework:SetFontColor(statusBar.text, "gray")

	GreatVaultAddon.ScrollFrame.create(f) 

	
	local openOptions2 = function()
		if GreatVaultAddonOptionsPanel then 
			GreatVaultAddonOptionsPanel:Show()
			return
		end


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

		local reloadSettingsButton = DetailsFramework:CreateButton(optionsFrame, reloadSettings, 130, 20, "Reload UI")
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

	function openOptions()
		GreatVaultAddonOptions:toggle()
	end
	
	local optButton = DetailsFramework:CreateButton(f, openOptions, 130, 14, "options", 14)
	optButton:SetPoint("bottomright", f, "bottomright", -10, 4)
	optButton.textsize = 12
	optButton.textcolor = "orange"

	DetailsFramework:AddRoundedCornersToFrame(optButton, {
		roundness = 0,
		color = {.2, .2, .2, 0.98},
		border_color = {.1, .1, .1, 0.834},
	})

end

function GreatVaultAddon.ScrollFrame.create(f) 
	GreatVaultAddon.ScrollFrame.setHeader(f)
	local scrollFrame = DetailsFramework:CreateScrollBox(f, "$parentScroll", GreatVaultAddon.ScrollFrame.RefreshScroll, GreatVaultAddon.db.global.characters, CONST_WINDOW_WIDTH, CONST_WINDOW_HEIGHT-70, GreatVaultAddon.db.global.greatvault_frame.lines, CONST_SCROLL_LINE_HEIGHT)
	DetailsFramework:ReskinSlider(scrollFrame)
	scrollFrame:CreateLines(GreatVaultAddon.ScrollFrame.CreateScrollLine, GreatVaultAddon.db.global.greatvault_frame.lines)
	scrollFrame:SetPoint("topleft", f.Header, "bottomleft", -1, -1)
	scrollFrame:SetPoint("topright", f.Header, "bottomright", 0, -1)
    scrollFrame:Refresh()
	GreatVaultAddon.ScrollFrame.ScollFrame = scrollFrame;
end

function GreatVaultAddon.ScrollFrame.setHeader(f)

	local headerOptions = {
		padding = 0,
		header_backdrop_color = {.3, .3, .3, .8},
		header_backdrop_color_selected = {.5, .5, .5, 0.8},
		use_line_separators = false,
		line_separator_color = {.1, .1, .1, .5},
		line_separator_width = 1,
		line_separator_height = CONST_WINDOW_HEIGHT-30,
		line_separator_gap_align = false,
		header_click_callback = function(headerFrame, columnHeader)
			GreatVaultAddon:sortEntries(columnHeader.key, columnHeader.order)
		end,
	}

	f.Header = DetailsFramework:CreateHeader(f, headerTable, headerOptions, "GreatVaultInfoFrameHeader")
	f.Header:SetPoint("topleft", f, "topleft", 3, -25)
    f.Header.columnSelected = 2
end

function GreatVaultAddon.ScrollFrame.RefreshScroll(self, data, offset, totalLines) 
	for i = 1, totalLines do
		local index = i + offset
		local data = data[index]
		if(data) then 
			local line = self:GetLine(i)
            if (data.name == PlayerName) then
                line:SetBackdropColor(unpack(backdrop_color_inparty))
            else
                line:SetBackdropColor(unpack(backdrop_color))
            end

			for key, value in pairs(colConfig) do
				if value["refresh"] then 
					local lineFn = value["refresh"]
					line = lineFn(line, data) 
				end
			end

			for key, items in pairs(viewTypes) do
				for idx, col in ipairs(items) do
					line[col].text = GreatVaultAddon:GetVault(data[key][idx], data.lastUpdated)
				end
			end

		end
	end
end

function GreatVaultAddon.ScrollFrame.CreateScrollLine(self, lineId)
	local line = CreateFrame("frame", "$parentLine" .. lineId, self, "BackdropTemplate")
	line.lineId = lineId

    line:SetPoint("TOPLEFT", self, "TOPLEFT", 2, (CONST_SCROLL_LINE_HEIGHT * (lineId - 1) * -1) - 2)
    line:SetPoint("TOPRIGHT", self, "TOPRIGHT", -2, (CONST_SCROLL_LINE_HEIGHT * (lineId - 1) * -1) - 2)
    line:SetHeight(CONST_SCROLL_LINE_HEIGHT)

    line:SetBackdrop({bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true})
    line:SetBackdropColor(unpack(backdrop_color))

	DetailsFramework:Mixin(line, DetailsFramework.HeaderFunctions)

    line:SetScript("OnEnter", function(self)
        if not (self.character.text == PlayerName) then
            self:SetBackdropColor(unpack(backdrop_color_on_enter))
        end
    end)

	line:SetScript("OnLeave", function(self)
        if not (self.character.text == PlayerName) then
            self:SetBackdropColor(unpack(backdrop_color))
        end
    end)

	local header = self:GetParent().Header

	for _, value in pairs(headerTableConfig) do
		if colConfig[value] and colConfig[value]["create"] then
			local lineFn = colConfig[value]["create"]
			line = lineFn(line)
		else
			local obj = DetailsFramework:CreateLabel(line)
			line[value] = obj
			line:AddFrameToHeaderAlignment(obj)
		end
	end

	line:AlignWithHeader(header, "left")
	return line
end



local function GetWeeklyQuestResetTime()
	local now = time()
	local region = GetCurrentRegion()
	local regionDayOffset = {{ 2, 1, 0, 6, 5, 4, 3 }, { 4, 3, 2, 1, 0, 6, 5 }, { 3, 2, 1, 0, 6, 5, 4 }, { 4, 3, 2, 1, 0, 6, 5 }, { 4, 3, 2, 1, 0, 6, 5 } }
	local nextDailyReset = GetQuestResetTime()
	local utc = date("!*t", now + nextDailyReset)
	local reset = regionDayOffset[region][utc.wday] * 86400 + now + nextDailyReset
	return reset
end

function GreatVaultAddon:GetVault(activity, lastUpdated)
	if not lastUpdated then
		lastUpdated = time()
	end

	local status = ""
	local activityThisWeek = lastUpdated > GetWeeklyQuestResetTime() - 604800
	local difficulty

	if activity.progress >= activity.threshold and activityThisWeek then
		if activity.type == Enum.WeeklyRewardChestThresholdType.Activities then
			difficulty = " +" .. activity.level .. " "
		elseif activity.type == Enum.WeeklyRewardChestThresholdType.RankedPvP then
			difficulty = PVPUtil.GetTierName(activity.level)
		elseif activity.type == Enum.WeeklyRewardChestThresholdType.Raid then
			difficulty = DIFFICULTY_NAMES[activity.level]
		end

		status = GREEN_FONT_COLOR_CODE .. difficulty .. FONT_COLOR_CODE_CLOSE
	else
		local progress = 0
		if activityThisWeek then
			progress = activity.progress
		end

		status = GRAY_FONT_COLOR_CODE .. progress .. '/' .. activity.threshold  ..  FONT_COLOR_CODE_CLOSE
	end

    return status
end

function GreatVaultAddon:SaveCharacterInfo(info)
	if UnitLevel("player") < 70 then
		return
	end
	
	playerConfig = info or self:GetCharacterInfo()
end

function GreatVaultAddon:GetCharacterInfo()
	local characterInfo = {}
	local found = false
	for _, value in ipairs(self.db.global.characters) do
        if value.name == PlayerName  then
			found = true
			characterInfo = value
        end
    end


	for _, value in pairs(colConfig) do
		if value["store"] then 
			local storeFn = value["store"]
			characterInfo = storeFn(characterInfo) 
		end
	end

	characterInfo.lastUpdate = time()

	if not found then 
		table.insert(self.db.global.characters, characterInfo)
	end

	return characterInfo
end


function GreatVaultAddon:UpdateCharacterInfo(pConfig)
	if pConfig then
		pConfig.lastUpdate = time()
		pConfig.raid = C_WeeklyRewards.GetActivities(Enum.WeeklyRewardChestThresholdType.Raid)
		pConfig.activities = C_WeeklyRewards.GetActivities(Enum.WeeklyRewardChestThresholdType.Activities)
		pConfig.pvp = C_WeeklyRewards.GetActivities(Enum.WeeklyRewardChestThresholdType.RankedPvP)
		return pConfig
	end
end


function GreatVaultAddon:WEEKLY_REWARDS_UPDATE(event)
	playerConfig = GreatVaultAddon:UpdateCharacterInfo(playerConfig)
end

function GreatVaultAddon:WEEKLY_REWARDS_ITEM_CHANGED(event)
	playerConfig = GreatVaultAddon:UpdateCharacterInfo(playerConfig)
end

function GreatVaultAddon:OnEnable()
	self:RegisterEvent("WEEKLY_REWARDS_UPDATE")
	self:RegisterEvent("WEEKLY_REWARDS_ITEM_CHANGED")
	
	--[[
	for _, value in pairs(colConfig) do
		if value["OnEnable"] then 
			local fn = value["OnEnable"]
			fn(self, value) 
		end
	end
	]]
end

function GreatVaultAddon:OnDisable()
	self:UnregisterEvent("WEEKLY_REWARDS_UPDATE")
	self:UnregisterEvent("WEEKLY_REWARDS_ITEM_CHANGED")

	--[[
	for _, value in pairs(colConfig) do
		if value["OnDisable"] then 
			local fn = value["OnDisable"]
			fn(self, value) 
		end
	end
	]]
end

function GreatVaultAddon_OnAddonCompartmentClick()
	GreatVaultInfoFrame:SetShown(not GreatVaultInfoFrame:IsShown()) 
end




function GreatVaultAddon:SetupColumns()

	CONST_WINDOW_WIDTH = 300
	viewTypes = {}
	headerTable = {}
	headerTableConfig = {}

	local columnsTable = GreatVaultAddon.db.global.columns
	columnsTable = _.sortBy(columnsTable, function(a) 
		return a.position 
	end)

	table.sort(columnsTable, function (a, b)
		if a.position == b.position then
			return  a.key < b.key 
		end
		return a.position < b.position 
	end)

	local size = 1

	_.forEach(columnsTable, function(col) 
		if not col.active then return end

		local colstart = size 
		size = size + col.size

		local key = col.key
		local value = colConfig[col.key]

		if not value then return end

		-- sortConfig
		if value.sort then
			sortConfig[value.sort.key] = value.sort.store
		end

		if value.subCols then 
			if value.header then
				viewTypes[key] = {}
				for idx = 1, value.subCols, 1 do
					local opt = shallowcopy(value.header)
					opt.key = key .. idx
					if idx > 1 then
						opt.text = ""
					end
					local pos = colstart + idx - 1
					table.insert(headerTable, pos, opt)
					table.insert(headerTableConfig, pos, opt.key)
					table.insert(viewTypes[key], opt.key)
				end
			end
		else
			-- headerTable
			if value.header then
				table.insert(headerTable, colstart, value.header)
				table.insert(headerTableConfig, colstart, col.key)
			end
		end


	--	table.insert(headerTable, colstart, colConfig[col.key].header)
	--	table.insert(headerTableConfig, colstart, col.key)

	
	end)

	local newheaderTableConfig = {}
	local newheaderTable =  {}
	local i = 0 
	for key, _ in pairs(headerTableConfig) do
		i = i + 1
		newheaderTableConfig[i] =  headerTableConfig[key]
		newheaderTable[i] =  headerTable[key]
	end

	headerTableConfig = newheaderTableConfig
	headerTable = newheaderTable



	local windowWidth = 0
	for _, value in ipairs(headerTable) do
		windowWidth = windowWidth + value.width
	end

	--frame options
	CONST_WINDOW_WIDTH = windowWidth + 30


end






GREATVAULTLIST_COLUMNS = {
    OnEnable = function(self)

		GreatVaultAddon.db.global.columns[self.key] = {
			['key'] = self.key,
			['active'] = GreatVaultAddon.db.global.columns[self.key].active,
			['position'] = GreatVaultAddon.db.global.columns[self.key].position or self.config.index,
			['size'] = self.config.subCols or 1
		}

		if not _.isBoolean(GreatVaultAddon.db.global.columns[self.key].active) then
			GreatVaultAddon.db.global.columns[self.key].active =  true
		end





		if GreatVaultAddon.db.global.columns[self.key].active then 
			colConfig[self.key] = self.config
		end

		self.loaded = true
      	GREATVAULTLIST_COLUMNS__checkModules()
    end,
    OnDisable = function(self)

		if not GreatVaultAddon.db.global.columns[self.key] then 
			GreatVaultAddon.db.global.columns[self.key].active = false
		end


        self.loaded = false
        GREATVAULTLIST_COLUMNS__checkModules()
    end 
}


function GREATVAULTLIST_COLUMNS__checkModules()
    local modules = GreatVaultAddon:IterateModules()
    local check = _.every(modules, function(module)
        return module.loaded
    end)

    if GREATVAULTLIST_COLUMNS__ticker then
        GREATVAULTLIST_COLUMNS__ticker:Cancel()
	end

    if check then
        GREATVAULTLIST_COLUMNS__ticker = C_Timer.NewTimer(0.1, function()
			GREATVAULTLIST_COLUMNS__ticker:Cancel()


			GreatVaultAddon.db.global.columns = _.forEach(GreatVaultAddon.db.global.columns, function(col)
				col.loaded = false
				return col
			end)
			for name, module in GreatVaultAddon:IterateModules() do
				GreatVaultAddon.db.global.columns[module.key].loaded = true
			end

--[[
			local colConfigTemp = {}
			local columsTemp = {}
			for name, module in GreatVaultAddon:IterateModules() do
				colConfigTemp[module.key] = colConfig[module.key]
				columsTemp = GreatVaultAddon.db.global.columns[module.key]
			end

			GreatVaultAddon.db.global.columns= columsTemp
			colConfig = colConfigTemp
--]]
			GreatVaultAddon:Initwindow()
        end)
    end
end
