local _ = ...

-- REASON: Localize globals for performance and to avoid global lookups.
local _G = _G
local CreateFrame = CreateFrame
local HideUIPanel = HideUIPanel
local InCombatLockdown = InCombatLockdown
local PanelTemplates_GetSelectedTab = PanelTemplates_GetSelectedTab
local UnitClass = UnitClass
local hooksecurefunc = hooksecurefunc
local select = select

-- REASON: Manage layout and appearance of the Inspect UI.
local module = CreateFrame("Frame", "Kkthnx_BetterInspectUI")
module:RegisterEvent("ADDON_LOADED")

module:SetScript("OnEvent", function(self, event, ...)
	local addon = ...

	-- REASON: Wait for the Blizzard_InspectUI addon to be loaded before applying customizations.
	if addon ~= "Blizzard_InspectUI" then
		return
	end

	-- REASON: Ensure the frame is hidden when customizations are first applied.
	local InspectFrame = _G.InspectFrame
	local InspectHandsSlot = _G.InspectHandsSlot
	local InspectHeadSlot = _G.InspectHeadSlot
	local InspectMainHandSlot = _G.InspectMainHandSlot
	local InspectModelFrame = _G.InspectModelFrame
	local InspectPaperDollItemsFrame = _G.InspectPaperDollItemsFrame
	local InspectSecondaryHandSlot = _G.InspectSecondaryHandSlot

	if InspectFrame:IsShown() then
		HideUIPanel(InspectFrame)
	end

	-- REASON: Reposition talent button for better layout integration.
	InspectPaperDollItemsFrame.InspectTalents:ClearAllPoints()
	InspectPaperDollItemsFrame.InspectTalents:SetPoint("TOPRIGHT", InspectFrame, "BOTTOMRIGHT", 0, -1)

	InspectModelFrame:StripTextures(true)

	-- REASON: Standardize item slot sizes and appearance in the inspect frame.
	local function styleItems(...)
		for i = 1, select("#", ...) do
			local slot = select(i, ...)
			if slot:IsObjectType("Button") or slot:IsObjectType("ItemButton") then
				slot:StripTextures()
				slot:SetSize(37, 37)
			end
		end
	end
	styleItems(InspectPaperDollItemsFrame:GetChildren())

	-- REASON: Position equipment slots and the model scene within the inspect frame.
	InspectHeadSlot:SetPoint("TOPLEFT", InspectFrame.Inset, "TOPLEFT", 6, -6)
	InspectHandsSlot:SetPoint("TOPRIGHT", InspectFrame.Inset, "TOPRIGHT", -6, -6)
	InspectMainHandSlot:SetPoint("BOTTOMLEFT", InspectFrame.Inset, "BOTTOMLEFT", 175, 5)
	InspectSecondaryHandSlot:ClearAllPoints()
	InspectSecondaryHandSlot:SetPoint("BOTTOMRIGHT", InspectFrame.Inset, "BOTTOMRIGHT", -175, 5)

	InspectModelFrame:SetSize(0, 0)
	InspectModelFrame:ClearAllPoints()
	InspectModelFrame:SetPoint("TOPLEFT", InspectFrame.Inset, 0, 0)
	InspectModelFrame:SetPoint("BOTTOMRIGHT", InspectFrame.Inset, 0, 30)
	InspectModelFrame:SetCamDistanceScale(1.1)

	-- REASON: Dynamically adjust the Inspect Frame size and background when switching tabs.
	local onInspectSwitchTabs = function(newID)
		-- WARNING: Avoid modification if in combat as the frame is secure.
		if InCombatLockdown() then
			return
		end

		local tabID = newID or PanelTemplates_GetSelectedTab(InspectFrame)
		if tabID == 1 then
			InspectFrame:SetSize(438, 431)
			InspectFrame.Inset:SetPoint("BOTTOMRIGHT", InspectFrame, "BOTTOMLEFT", 432, 4)

			local _, targetClass = UnitClass("target")
			if targetClass then
				InspectFrame.Inset.Bg:SetTexture("Interface\\DressUpFrame\\DressingRoom" .. targetClass)
				InspectFrame.Inset.Bg:SetTexCoord(0.00195312, 0.935547, 0.00195312, 0.978516)
				InspectFrame.Inset.Bg:SetHorizTile(false)
				InspectFrame.Inset.Bg:SetVertTile(false)
			end
		else
			InspectFrame:SetSize(338, 424)
			InspectFrame.Inset:SetPoint("BOTTOMRIGHT", InspectFrame, "BOTTOMLEFT", 332, 4)

			InspectFrame.Inset.Bg:SetTexture("Interface\\FrameGeneral\\UI-Background-Marble", "REPEAT", "REPEAT")
			InspectFrame.Inset.Bg:SetTexCoord(0, 1, 0, 1)
			InspectFrame.Inset.Bg:SetHorizTile(true)
			InspectFrame.Inset.Bg:SetVertTile(true)
		end
	end

	-- REASON: Ensure layout updates whenever the user switches tabs.
	hooksecurefunc("InspectSwitchTabs", onInspectSwitchTabs)

	-- REASON: Apply the customizations immediately for the first tab.
	onInspectSwitchTabs(1)

	self:UnregisterEvent(event)
end)
