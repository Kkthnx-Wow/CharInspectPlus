local _ = ...

-- REASON: Localize globals for performance and avoid global lookups in high-frequency operations.
local CreateFrame = CreateFrame
local EnumerateFrames = EnumerateFrames
local RegisterAttributeDriver = RegisterAttributeDriver
local RegisterStateDriver = RegisterStateDriver
local UIParent = UIParent
local _G = _G
local getmetatable = getmetatable
local select = select
local tonumber = tonumber
local type = type

-- REASON: Provide a hidden parent for frames that need to be effectively disabled.
local uiFrameHider = CreateFrame("Frame", "Kkthnx_UIFrameHider", UIParent, "SecureHandlerAttributeTemplate")
uiFrameHider:Hide()
uiFrameHider:SetPoint("TOPLEFT", 0, 0)
uiFrameHider:SetPoint("BOTTOMRIGHT", 0, 0)
RegisterAttributeDriver(uiFrameHider, "state-visibility", "hide")

-- REASON: Hide specific frames during pet battles to reduce visual clutter.
local petBattleHider = CreateFrame("Frame", "Kkthnx_PetBattleHider", UIParent, "SecureHandlerStateTemplate")
petBattleHider:SetAllPoints()
petBattleHider:SetFrameStrata("LOW")
RegisterStateDriver(petBattleHider, "visibility", "[petbattle] hide; show")

-- REASON: Completely disable an object by unregistering events and hiding it.
local function killObject(object)
	if object.UnregisterAllEvents then
		object:UnregisterAllEvents()
		object:SetParent(uiFrameHider)
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
					-- PERF: Setting texture to empty string is faster than hiding for many regions.
					region:SetTexture("")
				end
			else
				region:SetTexture("")
			end
		end
	end
end

-- REASON: Remove default Blizzard textures from frames for a cleaner UI look.
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

-- REASON: Extend the base WoW API with custom utility functions.
local function addApi(object)
	local mt = getmetatable(object).__index

	if not object.Kill then
		mt.Kill = killObject
	end

	if not object.StripTextures then
		mt.StripTextures = stripTextures
	end
end

-- REASON: Apply the custom API to all existing and future frames.
local handledFrames = { Frame = true }
local baseFrame = CreateFrame("Frame")
addApi(baseFrame)
addApi(baseFrame:CreateTexture())
addApi(baseFrame:CreateFontString())
addApi(baseFrame:CreateMaskTexture())

local currentObject = EnumerateFrames()
while currentObject do
	if not currentObject:IsForbidden() and not handledFrames[currentObject:GetObjectType()] then
		addApi(currentObject)
		handledFrames[currentObject:GetObjectType()] = true
	end

	currentObject = EnumerateFrames(currentObject)
end
