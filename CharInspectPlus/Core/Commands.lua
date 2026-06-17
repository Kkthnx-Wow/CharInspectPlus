--[[
	CharInspectPlus - Commands & Options
	-------------------------------------------------------------------------
	/cip slash command and Blizzard Settings panel integration.
--]]

local _, ns = ...
local F, C, L = ns.F, ns.C, ns.L

local CreateFrame = CreateFrame
local format = string.format
local C_AddOns = C_AddOns

local handlers = {}

handlers.help = function(_)
	F.Print(F.Colorize(L["Usage"] .. ":", "brand"))
	F.Print("  /cip help          -", L["Show this help"])
	F.Print("  /cip modules       -", L["List modules and their state"])
	F.Print("  /cip toggle <name> -", L["Toggle a module: /cip toggle <module>"])
	F.Print("  /cip config        -", L["Open the options panel"])
end

handlers.modules = function(_)
	F.Print(F.Colorize(L["Modules"] .. ":", "brand"))
	for i = 1, #ns.modules do
		local module = ns.modules[i]
		local state = module:IsEnabled() and F.Colorize(L["Enabled"], "green") or F.Colorize(L["Disabled"], "red")
		F.Print(" -", module.name, state)
	end
end

handlers.toggle = function(name)
	if not name or name == "" then
		F.Print(L["Usage"] .. ": /cip toggle <module>")
		return
	end

	local module = ns:GetModule(name)
	if not module or not module.dbKey then
		F.Print(F.Colorize(format(L["Unknown module '%s'."], name), "red"))
		return
	end

	local settings = ns.db[module.dbKey]
	settings.enable = not settings.enable
	local state = settings.enable and F.Colorize(L["Enabled"], "green") or F.Colorize(L["Disabled"], "red")
	F.Print(module.name, "->", state)

	if module.OnSettingChanged then
		module:OnSettingChanged("enable", settings.enable)
	end
	ns:TriggerCallback("SettingChanged." .. module.dbKey .. ".enable", settings.enable, module)
end

handlers.config = function(_)
	if ns.OpenOptions then
		ns:OpenOptions()
	else
		handlers.help()
	end
end

local function HandleSlash(input)
	input = (input or ""):gsub("^%s+", ""):gsub("%s+$", "")
	local command, rest = input:match("^(%S*)%s*(.-)$")
	command = command:lower()
	local handler = handlers[command] or handlers.help
	handler(rest)
end

_G.SLASH_CHARINSPECTPLUS1 = "/cip"
_G.SLASH_CHARINSPECTPLUS2 = "/charinspect"
_G.SLASH_CHARINSPECTPLUS3 = "/charinspectplus"
_G["SlashCmdList"]["CHARINSPECTPLUS"] = HandleSlash

local function Brand(text)
	return "|c" .. C.BrandHex .. text .. "|r"
end

local function ApplyModuleSetting(module, key, value)
	if module.OnSettingChanged then
		module:OnSettingChanged(key, value)
	end
	if module.dbKey then
		ns:TriggerCallback("SettingChanged." .. module.dbKey .. "." .. key, value, module)
	end
end

local OptionBuilder = {}

local function GetDefault(module, key)
	local defaults = ns.defaults.profile[module.dbKey]
	return defaults and defaults[key]
end

local function RegisterSetting(category, module, key, name)
	local variableTbl = ns.db[module.dbKey]
	local defaultValue = GetDefault(module, key)
	local variable = ns.name .. "_" .. module.dbKey .. "_" .. key
	local setting = Settings.RegisterAddOnSetting(category, variable, key, variableTbl, type(defaultValue), name, defaultValue)
	setting:SetValueChangedCallback(function(_, value)
		ApplyModuleSetting(module, key, value)
	end)
	return setting
end

function OptionBuilder:Description(text)
	local layout = self.layout
	if layout and F.CreateSettingsDescription then
		local desc = F.CreateSettingsDescription(text)
		if desc then
			layout:AddInitializer(desc)
		end
	end
end

function OptionBuilder:Header(text)
	local layout = self.layout
	if layout and _G["CreateSettingsListSectionHeaderInitializer"] then
		layout:AddInitializer(_G["CreateSettingsListSectionHeaderInitializer"](text))
	end
end

function OptionBuilder:Checkbox(category, module, key, name, tooltip)
	local setting = RegisterSetting(category, module, key, name)
	Settings.CreateCheckbox(category, setting, tooltip)
	return setting
end

-- ---------------------------------------------------------------------------
-- Landing page (root category — the page you see when you click the addon name)
-- ---------------------------------------------------------------------------
local function MakeFontString(parent, template)
	local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
	fs:SetJustifyH("LEFT")
	return fs
end

local function CreateLandingFrame()
	local frame = CreateFrame("Frame", nil)

	local logo = frame:CreateTexture(nil, "ARTWORK")
	logo:SetSize(64, 64)
	logo:SetPoint("TOPLEFT", 14, -14)
	logo:SetTexture(C_AddOns.GetAddOnMetadata(ns.name, "IconTexture") or 4952382)

	local title = MakeFontString(frame, "GameFontNormalHuge")
	title:SetPoint("TOPLEFT", logo, "TOPRIGHT", 14, -2)
	title:SetText(ns.title)

	local meta = MakeFontString(frame, "GameFontDisable")
	meta:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 1, -7)
	local author = C_AddOns.GetAddOnMetadata(ns.name, "Author") or "?"
	meta:SetText(format("%s %s   %s %s", L["Version"], Brand(ns.version), L["Author"], Brand(author)))

	local stats = MakeFontString(frame, "GameFontHighlight")
	stats:SetPoint("TOPLEFT", meta, "BOTTOMLEFT", 0, -4)
	frame.stats = stats

	local tagline = MakeFontString(frame, "GameFontHighlight")
	tagline:SetPoint("TOPLEFT", logo, "BOTTOMLEFT", 0, -16)
	tagline:SetPoint("RIGHT", frame, "RIGHT", -24, 0)
	tagline:SetWordWrap(true)
	tagline:SetText(L["Landing Tagline"])

	local divider = frame:CreateTexture(nil, "ARTWORK")
	divider:SetColorTexture(C.Colors.brand[1], C.Colors.brand[2], C.Colors.brand[3], 0.55)
	divider:SetHeight(2)
	divider:SetPoint("TOPLEFT", tagline, "BOTTOMLEFT", 0, -14)
	divider:SetPoint("RIGHT", frame, "RIGHT", -24, 0)

	local heading = MakeFontString(frame, "GameFontNormalLarge")
	heading:SetPoint("TOPLEFT", divider, "BOTTOMLEFT", 0, -12)
	heading:SetText(Brand(L["Getting Started"]))

	local lines = {
		{ "/cip config", L["Open the options panel"] },
		{ "/cip modules", L["List modules and their state"] },
		{ "/cip toggle <module>", L["Toggle a module: /cip toggle <module>"] },
		{ "/cip help", L["Show this help"] },
	}

	local anchor = heading
	for i = 1, #lines do
		local row = MakeFontString(frame, "GameFontHighlight")
		row:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", i == 1 and 6 or 0, i == 1 and -8 or -5)
		row:SetText(format("%s  |cffaaaaaa%s|r", Brand(lines[i][1]), lines[i][2]))
		anchor = row
	end

	local hint = MakeFontString(frame, "GameFontDisable")
	hint:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 6, -14)
	hint:SetPoint("RIGHT", frame, "RIGHT", -24, 0)
	hint:SetWordWrap(true)
	hint:SetText(L["Landing Settings Hint"])

	function frame:OnRefresh()
		local total, enabled = #ns.modules, 0
		for i = 1, total do
			if ns.modules[i]:IsEnabled() then
				enabled = enabled + 1
			end
		end
		self.stats:SetFormattedText(L["%d modules, %d enabled"], total, enabled)
	end

	for i = 1, #ns.modules do
		local module = ns.modules[i]
		if module.dbKey then
			ns:RegisterCallback("SettingChanged." .. module.dbKey .. ".enable", "OnRefresh", frame)
		end
	end
	frame:OnRefresh()

	return frame
end

local function BuildOptions()
	if not (Settings and Settings.RegisterVerticalLayoutCategory) then
		return
	end

	local category
	if Settings.RegisterCanvasLayoutCategory then
		category = Settings.RegisterCanvasLayoutCategory(CreateLandingFrame(), ns.title)
	else
		category = Settings.RegisterVerticalLayoutCategory(ns.title)
	end
	ns.settingsCategory = category

	local subCategory, layout
	if Settings.RegisterVerticalLayoutSubcategory then
		subCategory, layout = Settings.RegisterVerticalLayoutSubcategory(category, L["General"])
		ns.settingsSubCategory = subCategory
	end

	OptionBuilder.layout = layout
	if layout then
		OptionBuilder:Description(L["DESC_GENERAL"])
	end

	for i = 1, #ns.modules do
		local module = ns.modules[i]
		if module.RegisterOptions then
			if layout then
				OptionBuilder:Header(module.title or module.name)
			end
			module:RegisterOptions(subCategory or category, OptionBuilder)
		end
	end
	OptionBuilder.layout = nil

	Settings.RegisterAddOnCategory(category)

	function ns:OpenOptions()
		local target = ns.settingsSubCategory or ns.settingsCategory
		if Settings.OpenToCategory and target then
			Settings.OpenToCategory(target.ID)
		end
	end
end

ns:RegisterEvent("PLAYER_LOGIN", BuildOptions)
