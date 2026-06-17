--[[
	CharInspectPlus - Settings widgets
	-------------------------------------------------------------------------
	Minimal helpers for Blizzard's vertical Settings layout.
--]]

local _, ns = ...
local F = ns.F

local UIParent = UIParent
local Settings = Settings

CharInspectPlusSettingsDescriptionMixin = {}

function CharInspectPlusSettingsDescriptionMixin:Init(initializer)
	local data = initializer:GetData()
	self.Text:SetText(data and data.text or "")
end

local descMeasure
local DESC_MEASURE_WIDTH = 500
local DESC_PADDING = 14

local function MeasureDescriptionHeight(text)
	if not descMeasure then
		descMeasure = UIParent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		descMeasure:Hide()
		descMeasure:SetWidth(DESC_MEASURE_WIDTH)
		descMeasure:SetJustifyH("LEFT")
		descMeasure:SetWordWrap(true)
	end
	descMeasure:SetText(text or "")
	return (descMeasure:GetStringHeight() or 12) + DESC_PADDING
end

function F.CreateSettingsDescription(text)
	if not (Settings and Settings.CreateElementInitializer) then
		return
	end
	local initializer = Settings.CreateElementInitializer("CharInspectPlusSettingsDescriptionTemplate", { text = text })
	local height = MeasureDescriptionHeight(text)
	initializer.GetExtent = function()
		return height
	end
	return initializer
end
