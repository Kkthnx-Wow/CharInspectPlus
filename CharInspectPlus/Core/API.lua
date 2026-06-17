--[[
	CharInspectPlus - Widget API
	-------------------------------------------------------------------------
	Framework extensions: :Kill() and :StripTextures() on every widget.
	Standard ElvUI / KkthnxUI pattern used across character-frame skinning.
--]]

local _, ns = ...
local F = ns.F

local _G = _G
local CreateFrame = CreateFrame
local EnumerateFrames = EnumerateFrames
local RegisterAttributeDriver = RegisterAttributeDriver
local UIParent = UIParent
local getmetatable = getmetatable
local select = select
local tonumber = tonumber
local type = type

local hider = CreateFrame("Frame", "CharInspectPlusUIHider", UIParent, "SecureHandlerAttributeTemplate")
hider:Hide()
hider:SetPoint("TOPLEFT", 0, 0)
hider:SetPoint("BOTTOMRIGHT", 0, 0)
RegisterAttributeDriver(hider, "state-visibility", "hide")
ns.HiderFrame = hider

local function killObject(object)
	if object.UnregisterAllEvents then
		object:UnregisterAllEvents()
		object:SetParent(hider)
	else
		object.Show = object.Hide
	end
	object:Hide()
end

local BLIZZARD_TEXTURES = {
	"Inset",
	"inset",
	"InsetFrame",
	"LeftInset",
	"RightInset",
	"NineSlice",
	"BG",
	"Bg",
	"border",
	"Border",
	"Background",
	"BorderFrame",
	"bottomInset",
	"BottomInset",
	"bgLeft",
	"bgRight",
	"FilligreeOverlay",
	"PortraitOverlay",
	"ArtOverlayFrame",
	"Portrait",
	"portrait",
	"ScrollFrameBorder",
	"ScrollUpBorder",
	"ScrollDownBorder",
	"TitleWidgetContainer",
}

local function processRegions(shouldKill, ...)
	for i = 1, select("#", ...) do
		local region = select(i, ...)
		if region and region.IsObjectType and region:IsObjectType("Texture") then
			if shouldKill and type(shouldKill) == "boolean" then
				killObject(region)
			elseif tonumber(shouldKill) then
				if shouldKill == 0 then
					region:SetAlpha(0)
				elseif i ~= shouldKill then
					region:SetTexture("")
				end
			else
				region:SetTexture("")
			end
		end
	end
end

local function stripTextures(object, shouldKill)
	local frameName = object.GetName and object:GetName()
	for i = 1, #BLIZZARD_TEXTURES do
		local texture = BLIZZARD_TEXTURES[i]
		local blizzFrame = object[texture] or (frameName and _G[frameName .. texture])
		if blizzFrame then
			stripTextures(blizzFrame, shouldKill)
		end
	end

	if object.GetRegions then
		processRegions(shouldKill, object:GetRegions())
	end
end

F.Kill = killObject
F.StripTextures = stripTextures

local function addApi(object)
	local mt = getmetatable(object).__index
	if not object.Kill then
		mt.Kill = killObject
	end
	if not object.StripTextures then
		mt.StripTextures = stripTextures
	end
end

local handledTypes = { Frame = true }
local base = CreateFrame("Frame")
addApi(base)
addApi(base:CreateTexture())
addApi(base:CreateFontString())
addApi(base:CreateMaskTexture())

local object = EnumerateFrames()
while object do
	if not object:IsForbidden() and not handledTypes[object:GetObjectType()] then
		addApi(object)
		handledTypes[object:GetObjectType()] = true
	end
	object = EnumerateFrames(object)
end
