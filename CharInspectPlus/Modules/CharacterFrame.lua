local _ = ...

-- REASON: Localize globals for performance and to avoid global lookups.
local _G = _G
local CreateFrame = CreateFrame
local CharacterFrame = _G.CharacterFrame
local CharacterHandsSlot = _G.CharacterHandsSlot
local CharacterHeadSlot = _G.CharacterHeadSlot
local CharacterMainHandSlot = _G.CharacterMainHandSlot
local CharacterModelScene = _G.CharacterModelScene
local CharacterSecondaryHandSlot = _G.CharacterSecondaryHandSlot
local CharacterStatsPane = _G.CharacterStatsPane
local HideUIPanel = HideUIPanel
local InCombatLockdown = InCombatLockdown
local CharacterFrameInsetRight = _G.CharacterFrameInsetRight
local PaperDollFrame = _G.PaperDollFrame
local PaperDollItemsFrame = _G.PaperDollItemsFrame
local UnitClass = UnitClass
local hooksecurefunc = hooksecurefunc
local select = select

-- REASON: Manage layout and appearance of the Character Frame.
local module = CreateFrame("Frame", "Kkthnx_BetterCharacterFrame")
module:RegisterEvent("PLAYER_LOGIN")

module:SetScript("OnEvent", function(self, event, ...)
	-- REASON: Ensure the frame is hidden on login to apply initial customizations correctly.
	if CharacterFrame:IsShown() then
		HideUIPanel(CharacterFrame)
	end

	-- REASON: Remove default backgrounds and borders for a cleaner look.
	CharacterModelScene:DisableDrawLayer("BACKGROUND")
	CharacterModelScene:DisableDrawLayer("BORDER")
	CharacterModelScene:DisableDrawLayer("OVERLAY")
	CharacterModelScene:StripTextures(true)

	-- REASON: Standardize item slot sizes and appearance.
	local function styleItems(...)
		for i = 1, select("#", ...) do
			local slot = select(i, ...)
			if slot:IsObjectType("Button") or slot:IsObjectType("ItemButton") then
				slot:StripTextures()
				slot:SetSize(37, 37)
			end
		end
	end
	styleItems(PaperDollItemsFrame:GetChildren())

	-- REASON: Position equipment slots and the model scene within the inset.
	CharacterHeadSlot:SetPoint("TOPLEFT", CharacterFrame.Inset, "TOPLEFT", 6, -6)
	CharacterHandsSlot:SetPoint("TOPRIGHT", CharacterFrame.Inset, "TOPRIGHT", -6, -6)
	CharacterMainHandSlot:SetPoint("BOTTOMLEFT", CharacterFrame.Inset, "BOTTOMLEFT", 176, 5)
	CharacterSecondaryHandSlot:ClearAllPoints()
	CharacterSecondaryHandSlot:SetPoint("BOTTOMRIGHT", CharacterFrame.Inset, "BOTTOMRIGHT", -176, 5)

	CharacterModelScene:SetSize(0, 0)
	CharacterModelScene:ClearAllPoints()
	CharacterModelScene:SetPoint("TOPLEFT", CharacterFrame.Inset, 0, 0)
	CharacterModelScene:SetPoint("BOTTOMRIGHT", CharacterFrame.Inset, 0, 20)

	-- REASON: Dynamically adjust the Character Frame size and background when switching tabs.
	hooksecurefunc(CharacterFrame, "UpdateSize", function()
		-- WARNING: Avoid modification if in combat as the frame is secure.
		if InCombatLockdown() then
			return
		end

		if CharacterFrame.activeSubframe == "PaperDollFrame" then
			CharacterFrame:SetSize(640, 431)
			CharacterFrame.Inset:SetPoint("BOTTOMRIGHT", CharacterFrame, "BOTTOMLEFT", 432, 4)

			local _, class = UnitClass("player")
			CharacterFrame.Inset.Bg:SetTexture("Interface\\DressUpFrame\\DressingRoom" .. class)
			CharacterFrame.Inset.Bg:SetTexCoord(1 / 512, 479 / 512, 46 / 512, 455 / 512)
			CharacterFrame.Inset.Bg:SetHorizTile(false)
			CharacterFrame.Inset.Bg:SetVertTile(false)

			CharacterFrame.Background:Hide()
		else
			CharacterFrame.Background:Show()
		end
	end)

	-- REASON: Enhance the item level display for better readability.
	local charItemLevelValue = CharacterStatsPane.ItemLevelFrame.Value
	charItemLevelValue:SetFont(select(1, charItemLevelValue:GetFont()), 20, select(3, ""))
	charItemLevelValue:SetShadowOffset(1, -1)

	-- REASON: Clean up the Title Manager list appearance.
	local function styleTitleChildren(...)
		for i = 1, select("#", ...) do
			local child = select(i, ...)
			if child and not child.styled then
				child:DisableDrawLayer("BACKGROUND")
				child.styled = true
			end
		end
	end

	hooksecurefunc(PaperDollFrame.TitleManagerPane.ScrollBox, "Update", function(scrollBox)
		styleTitleChildren(scrollBox.ScrollTarget:GetChildren())
	end)

	-- REASON: Re-anchor the class background to fit the new layout.
	CharacterStatsPane.ClassBackground:ClearAllPoints()
	CharacterStatsPane.ClassBackground:SetHeight(CharacterStatsPane.ClassBackground:GetHeight() + 6)
	CharacterStatsPane.ClassBackground:SetParent(CharacterFrameInsetRight)
	CharacterStatsPane.ClassBackground:SetPoint("CENTER")
end)
