--[[
	CharInspectPlus - CharacterFrames
	-------------------------------------------------------------------------
	Cleans up and resizes the Character and Inspect frames: strips Blizzard
	textures, standardises item-slot sizes, repositions the model and slots,
	and swaps in a class dressing-room background on the gear tab.

	Live toggle: layout and backgrounds restore when disabled; stripped slot
	borders stay gone until /reload (Blizzard doesn't ship an undo button).
--]]

---@diagnostic disable: undefined-field
local _, ns = ...
local L, F, C = ns.L, ns.F, ns.C

local _G = _G
local select = select
local hooksecurefunc = hooksecurefunc
local InCombatLockdown = InCombatLockdown
local HideUIPanel = HideUIPanel
local UnitClass = UnitClass
local PanelTemplates_GetSelectedTab = PanelTemplates_GetSelectedTab
local C_AddOns = C_AddOns

ns:RegisterDefaults({
	characterFrames = {
		enable = true,
		characterFrame = true,
		inspectFrame = true,
	},
})

local Mod = ns:NewModule("CharacterFrames", "characterFrames", {
	group = "general",
	title = L["Character Frames"],
	order = 10,
})

-- Blizzard panel constants (12.0.7: CharacterFrame.lua, Constants.lua, SharedUIPanelTemplates.lua)
local PANEL_DEFAULT_WIDTH = _G.PANEL_DEFAULT_WIDTH or 338
local PANEL_DEFAULT_HEIGHT = _G.PANEL_DEFAULT_HEIGHT or 424
local PANEL_INSET_LEFT_OFFSET = _G.PANEL_INSET_LEFT_OFFSET or 4
local PANEL_INSET_RIGHT_OFFSET = _G.PANEL_INSET_RIGHT_OFFSET or -6
local PANEL_INSET_BOTTOM_OFFSET = _G.PANEL_INSET_BOTTOM_OFFSET or 4
local PANEL_INSET_BOTTOM_BUTTON_OFFSET = _G.PANEL_INSET_BOTTOM_BUTTON_OFFSET or 26
local PANEL_INSET_ATTIC_OFFSET = _G.PANEL_INSET_ATTIC_OFFSET or -60
local CHARACTERFRAME_EXPANDED_WIDTH = _G.CHARACTERFRAME_EXPANDED_WIDTH or 540

-- Wider than Blizzard's 540 expanded width; inset offset grows by the same delta so
-- InsetRight (stats pane) keeps the same width Blizzard expects.
local CHAR_PAPERDOLL_WIDTH = 640
local CHAR_PAPERDOLL_HEIGHT = 431
local CHAR_INSET_OFFSET = PANEL_DEFAULT_WIDTH + PANEL_INSET_RIGHT_OFFSET + (CHAR_PAPERDOLL_WIDTH - CHARACTERFRAME_EXPANDED_WIDTH)

local INSPECT_PAPERDOLL_WIDTH = 438
local INSPECT_PAPERDOLL_HEIGHT = 431
local INSPECT_INSET_OFFSET_PAPER = 432
local INSPECT_TAB_PVP = 2
local INSPECT_TAB_GUILD = 3
local SLOT_SIZE = 37
local CHAR_MODEL_ZOOM_SCALE = 1.1

local function StyleItemSlots(...)
	for i = 1, select("#", ...) do
		local slot = select(i, ...)
		local name = slot and slot.GetName and slot:GetName()
		if name and name:find("Slot") and (slot:IsObjectType("Button") or slot:IsObjectType("ItemButton")) then
			slot:StripTextures()
			slot:SetSize(SLOT_SIZE, SLOT_SIZE)
		end
	end
end

local function SetMarbleBackground(bg)
	if not bg then
		return
	end
	bg:SetTexture(C.Media.Textures.marble, "REPEAT", "REPEAT")
	bg:SetTexCoord(0, 1, 0, 1)
	bg:SetHorizTile(true)
	bg:SetVertTile(true)
end

-- Default ButtonFrameTemplate inset (SharedUIPanelTemplates.xml). Used when leaving
-- our widened paper-doll layout on Inspect, and when restoring disabled styling.
local function ApplyDefaultInset(frame, useButtonBar)
	frame.Inset:ClearAllPoints()
	frame.Inset:SetPoint("TOPLEFT", frame, "TOPLEFT", PANEL_INSET_LEFT_OFFSET, PANEL_INSET_ATTIC_OFFSET)
	local bottom = useButtonBar and PANEL_INSET_BOTTOM_BUTTON_OFFSET or PANEL_INSET_BOTTOM_OFFSET
	frame.Inset:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", PANEL_INSET_RIGHT_OFFSET, bottom)
end

-- Paper-doll static inset anchor (CharacterFrameMixin:UpdateSize, useStaticInsetSize).
local function ApplyPaperdollInset(frame, offsetX)
	frame.Inset:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", offsetX, PANEL_INSET_BOTTOM_OFFSET)
end

function Mod:ShouldStyleCharacter()
	local db = ns.db.characterFrames
	return self:IsEnabled() and db.characterFrame
end

function Mod:ShouldStyleInspect()
	local db = ns.db.characterFrames
	return self:IsEnabled() and db.inspectFrame
end

-- ---------------------------------------------------------------------------
-- Character model zoom (ModelScene has no SetCamDistanceScale)
-- ---------------------------------------------------------------------------
local function AdjustCharacterModelZoom()
	local scene = _G.CharacterModelScene
	local camera = scene and scene.GetActiveCamera and scene:GetActiveCamera()
	if not (camera and camera.GetZoomDistance and camera.SetZoomDistance) then
		return
	end

	local distance = camera:GetZoomDistance()
	if not distance then
		return
	end

	local target = distance * CHAR_MODEL_ZOOM_SCALE
	local maxDistance = camera.GetMaxZoomDistance and camera:GetMaxZoomDistance()
	if maxDistance and maxDistance > 0 and target > maxDistance then
		target = maxDistance
	end

	camera:SetZoomDistance(target)
	if camera.SnapToTargetInterpolationZoom then
		camera:SnapToTargetInterpolationZoom()
	end
end

-- ---------------------------------------------------------------------------
-- Character frame
-- ---------------------------------------------------------------------------
function Mod:ApplyCharacterLayout()
	if InCombatLockdown() or not self:ShouldStyleCharacter() then
		return
	end

	local CharacterFrame = _G.CharacterFrame
	if not CharacterFrame then
		return
	end

	local subframe = CharacterFrame.activeSubframe

	if subframe == "PaperDollFrame" then
		-- Only widen when the stats sidebar is expanded; collapsed gear tab keeps
		-- Blizzard's UpdateSize() width (338) and static inset (332).
		if CharacterFrame.Expanded then
			CharacterFrame:SetSize(CHAR_PAPERDOLL_WIDTH, CHAR_PAPERDOLL_HEIGHT)
			ApplyPaperdollInset(CharacterFrame, CHAR_INSET_OFFSET)
		end

		local _, class = UnitClass("player")
		if class then
			CharacterFrame.Inset.Bg:SetTexture("Interface\\DressUpFrame\\DressingRoom" .. class)
			CharacterFrame.Inset.Bg:SetTexCoord(1 / 512, 479 / 512, 46 / 512, 455 / 512)
			CharacterFrame.Inset.Bg:SetHorizTile(false)
			CharacterFrame.Inset.Bg:SetVertTile(false)
		end

		CharacterFrame.Background:Hide()
	elseif subframe == "ReputationFrame" or subframe == "TokenFrame" then
		-- UpdateSize() already set width (400) and Inset -> BOTTOMRIGHT (-6, 4).
		-- Touching anchors here was what broke Reputation / Currency tabs.
		CharacterFrame.Background:Show()
	end
end

function Mod:RestoreCharacterLayout()
	if InCombatLockdown() then
		self.pendingCharacterRestore = true
		return
	end

	local CharacterFrame = _G.CharacterFrame
	if not CharacterFrame then
		return
	end

	CharacterFrame.Background:Show()
	if CharacterFrame.UpdateSize then
		CharacterFrame:UpdateSize()
	end
end

function Mod:StyleCharacterFrame()
	if self.charStyled then
		self:ApplyCharacterLayout()
		return
	end
	self.charStyled = true

	local CharacterFrame = _G.CharacterFrame
	local CharacterModelScene = _G.CharacterModelScene
	local PaperDollItemsFrame = _G.PaperDollItemsFrame
	local CharacterStatsPane = _G.CharacterStatsPane
	local CharacterFrameInsetRight = _G.CharacterFrameInsetRight
	if not (CharacterFrame and CharacterModelScene) then
		return
	end

	if CharacterFrame:IsShown() then
		HideUIPanel(CharacterFrame)
	end

	CharacterModelScene:DisableDrawLayer("BACKGROUND")
	CharacterModelScene:DisableDrawLayer("BORDER")
	CharacterModelScene:DisableDrawLayer("OVERLAY")
	CharacterModelScene:StripTextures(true)

	StyleItemSlots(PaperDollItemsFrame:GetChildren())

	_G.CharacterHeadSlot:SetPoint("TOPLEFT", CharacterFrame.Inset, "TOPLEFT", 6, -6)
	_G.CharacterHandsSlot:SetPoint("TOPRIGHT", CharacterFrame.Inset, "TOPRIGHT", -6, -6)
	_G.CharacterMainHandSlot:SetPoint("BOTTOMLEFT", CharacterFrame.Inset, "BOTTOMLEFT", 176, 5)
	_G.CharacterSecondaryHandSlot:ClearAllPoints()
	_G.CharacterSecondaryHandSlot:SetPoint("BOTTOMRIGHT", CharacterFrame.Inset, "BOTTOMRIGHT", -176, 5)

	CharacterModelScene:SetSize(0, 0)
	CharacterModelScene:ClearAllPoints()
	CharacterModelScene:SetPoint("TOPLEFT", CharacterFrame.Inset, 4, -4)
	CharacterModelScene:SetPoint("BOTTOMRIGHT", CharacterFrame.Inset, -4, 4)

	if not self.charUpdateHooked then
		self.charUpdateHooked = true
		hooksecurefunc(CharacterFrame, "UpdateSize", function()
			Mod:ApplyCharacterLayout()
		end)
	end

	local itemLevelValue = CharacterStatsPane.ItemLevelFrame.Value
	local ilvlFont, _, ilvlFlags = itemLevelValue:GetFont()
	itemLevelValue:SetFont(ilvlFont, 20, ilvlFlags)
	itemLevelValue:SetShadowOffset(1, -1)

	local function StyleTitleChildren(...)
		for i = 1, select("#", ...) do
			local child = select(i, ...)
			if child and not child.cipStyled then
				child:DisableDrawLayer("BACKGROUND")
				child.cipStyled = true
			end
		end
	end

	hooksecurefunc(PaperDollFrame.TitleManagerPane.ScrollBox, "Update", function(scrollBox)
		if Mod:ShouldStyleCharacter() then
			StyleTitleChildren(scrollBox.ScrollTarget:GetChildren())
		end
	end)

	CharacterStatsPane.ClassBackground:ClearAllPoints()
	CharacterStatsPane.ClassBackground:SetHeight(CharacterStatsPane.ClassBackground:GetHeight() + 6)
	CharacterStatsPane.ClassBackground:SetParent(CharacterFrameInsetRight)
	CharacterStatsPane.ClassBackground:SetPoint("CENTER")

	if _G.PaperDollFrame_SetPlayer then
		hooksecurefunc("PaperDollFrame_SetPlayer", function()
			if Mod:ShouldStyleCharacter() then
				AdjustCharacterModelZoom()
			end
		end)
	end

	self:ApplyCharacterLayout()
	AdjustCharacterModelZoom()
end

-- ---------------------------------------------------------------------------
-- Inspect frame (Blizzard_InspectUI - load on demand)
-- ---------------------------------------------------------------------------
function Mod:ApplyInspectLayout(tabID)
	if InCombatLockdown() or not self:ShouldStyleInspect() then
		return
	end

	local InspectFrame = _G.InspectFrame
	if not InspectFrame then
		return
	end

	tabID = tabID or PanelTemplates_GetSelectedTab(InspectFrame)
	if tabID == 1 then
		InspectFrame:SetSize(INSPECT_PAPERDOLL_WIDTH, INSPECT_PAPERDOLL_HEIGHT)
		ApplyPaperdollInset(InspectFrame, INSPECT_INSET_OFFSET_PAPER)

		local _, targetClass = UnitClass("target")
		if F.NotSecret(targetClass) and targetClass then
			InspectFrame.Inset.Bg:SetTexture("Interface\\DressUpFrame\\DressingRoom" .. targetClass)
			InspectFrame.Inset.Bg:SetTexCoord(0.00195312, 0.935547, 0.00195312, 0.978516)
			InspectFrame.Inset.Bg:SetHorizTile(false)
			InspectFrame.Inset.Bg:SetVertTile(false)
		end
	else
		-- PVP / Guild: default panel size and template inset. Subframe OnShow toggles
		-- the button bar (PVP hides, Guild shows); match that when picking bottom inset.
		InspectFrame:SetSize(PANEL_DEFAULT_WIDTH, PANEL_DEFAULT_HEIGHT)
		ApplyDefaultInset(InspectFrame, tabID == INSPECT_TAB_GUILD)
		SetMarbleBackground(InspectFrame.Inset.Bg)
	end
end

function Mod:RestoreInspectLayout()
	if InCombatLockdown() then
		self.pendingInspectRestore = true
		return
	end

	local InspectFrame = _G.InspectFrame
	if not InspectFrame then
		return
	end

	InspectFrame:SetSize(PANEL_DEFAULT_WIDTH, PANEL_DEFAULT_HEIGHT)
	local tabID = PanelTemplates_GetSelectedTab(InspectFrame)
	ApplyDefaultInset(InspectFrame, tabID == INSPECT_TAB_GUILD)
	SetMarbleBackground(InspectFrame.Inset.Bg)
end

function Mod:StyleInspectFrame()
	if self.inspectStyled then
		self:ApplyInspectLayout()
		return
	end

	local InspectFrame = _G.InspectFrame
	local InspectModelFrame = _G.InspectModelFrame
	local InspectPaperDollItemsFrame = _G.InspectPaperDollItemsFrame
	if not (InspectFrame and InspectModelFrame and InspectPaperDollItemsFrame) then
		return
	end

	self.inspectStyled = true

	if InspectFrame:IsShown() then
		HideUIPanel(InspectFrame)
	end

	InspectPaperDollItemsFrame.InspectTalents:ClearAllPoints()
	InspectPaperDollItemsFrame.InspectTalents:SetPoint("TOPRIGHT", InspectFrame, "BOTTOMRIGHT", 0, -1)

	InspectModelFrame:StripTextures(true)
	StyleItemSlots(InspectPaperDollItemsFrame:GetChildren())

	_G.InspectHeadSlot:SetPoint("TOPLEFT", InspectFrame.Inset, "TOPLEFT", 6, -6)
	_G.InspectHandsSlot:SetPoint("TOPRIGHT", InspectFrame.Inset, "TOPRIGHT", -6, -6)
	_G.InspectMainHandSlot:SetPoint("BOTTOMLEFT", InspectFrame.Inset, "BOTTOMLEFT", 175, 5)
	_G.InspectSecondaryHandSlot:ClearAllPoints()
	_G.InspectSecondaryHandSlot:SetPoint("BOTTOMRIGHT", InspectFrame.Inset, "BOTTOMRIGHT", -175, 5)

	InspectModelFrame:SetSize(0, 0)
	InspectModelFrame:ClearAllPoints()
	InspectModelFrame:SetPoint("TOPLEFT", InspectFrame.Inset, 0, 0)
	InspectModelFrame:SetPoint("BOTTOMRIGHT", InspectFrame.Inset, 0, 30)
	InspectModelFrame:SetCamDistanceScale(1.1)

	local averageItemLevelText = InspectPaperDollItemsFrame:CreateFontString(nil, "ARTWORK")
	averageItemLevelText:SetFontObject("GameFontNormal")
	local aiFont, _, aiFlags = averageItemLevelText:GetFont()
	averageItemLevelText:SetFont(aiFont, 12, aiFlags)
	averageItemLevelText:SetShadowOffset(1, -1)
	averageItemLevelText:SetJustifyH("CENTER")
	averageItemLevelText:SetPoint("BOTTOM", InspectFrame.Inset, "BOTTOM", 0, 46)
	InspectPaperDollItemsFrame.AverageItemLevelText = averageItemLevelText

	if _G.InspectPaperDollFrame_SetLevel and _G.C_PaperDollInfo and _G.C_PaperDollInfo.GetInspectItemLevel then
		hooksecurefunc("InspectPaperDollFrame_SetLevel", function()
			if not Mod:ShouldStyleInspect() then
				return
			end
			local unit = InspectFrame.unit
			if not unit then
				return
			end
			local ilvl = _G.C_PaperDollInfo.GetInspectItemLevel(unit)
			if ilvl and F.NotSecret(ilvl) then
				averageItemLevelText:SetFormattedText(_G.DUNGEON_SCORE_LINK_ITEM_LEVEL or "Item Level %d", ilvl)
			end
		end)
	end

	if not self.inspectTabHooked then
		self.inspectTabHooked = true
		hooksecurefunc("InspectSwitchTabs", function(newID)
			Mod:ApplyInspectLayout(newID)
		end)
	end

	self:ApplyInspectLayout(1)
end

function Mod:ADDON_LOADED(addon)
	if addon == "Blizzard_InspectUI" and self:ShouldStyleInspect() then
		self:StyleInspectFrame()
	end
end

-- ---------------------------------------------------------------------------
-- Lifecycle & live settings
-- ---------------------------------------------------------------------------
function Mod:PLAYER_REGEN_ENABLED()
	if self.pendingCharacterRestore then
		self.pendingCharacterRestore = nil
		if not self:ShouldStyleCharacter() then
			self:RestoreCharacterLayout()
		end
	end
	if self.pendingInspectRestore then
		self.pendingInspectRestore = nil
		if not self:ShouldStyleInspect() then
			self:RestoreInspectLayout()
		end
	end
end

function Mod:OnInitialize()
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("ADDON_LOADED")
end

function Mod:OnEnable()
	self:StyleCharacterFrame()

	if C_AddOns.IsAddOnLoaded("Blizzard_InspectUI") then
		self:StyleInspectFrame()
	end
end

function Mod:OnSettingChanged(key, _)
	if key == "enable" or key == "characterFrame" then
		if self:ShouldStyleCharacter() then
			self:StyleCharacterFrame()
		else
			self:RestoreCharacterLayout()
		end
	end

	if key == "enable" or key == "inspectFrame" then
		local ilvlText = _G.InspectPaperDollItemsFrame and _G.InspectPaperDollItemsFrame.AverageItemLevelText
		if self:ShouldStyleInspect() then
			if C_AddOns.IsAddOnLoaded("Blizzard_InspectUI") then
				self:StyleInspectFrame()
			end
			if ilvlText then
				ilvlText:Show()
			end
		else
			self:RestoreInspectLayout()
			if ilvlText then
				ilvlText:Hide()
			end
		end
	end
end

function Mod:RegisterOptions(category, builder)
	builder:Checkbox(category, self, "enable", L["Enable CharInspectPlus"], L["Enable CharInspectPlus Tip"])
	builder:Checkbox(category, self, "characterFrame", L["Enable Character Frame"], L["Enable Character Frame Tip"])
	builder:Checkbox(category, self, "inspectFrame", L["Enable Inspect Frame"], L["Enable Inspect Frame Tip"])
end
