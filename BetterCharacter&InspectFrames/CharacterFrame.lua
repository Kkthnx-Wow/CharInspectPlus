--[[
	The MIT License (MIT)
	Copyright (c) 2022 Josh 'Kkthnx' Russell
	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:
	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
--]]

local Module = CreateFrame("Frame", "Kkthnx_BetterCharacterFrame")
Module:RegisterEvent("PLAYER_LOGIN")

local _G = _G
local select = _G.select

local CharacterHandsSlot = _G.CharacterHandsSlot
local CharacterHeadSlot = _G.CharacterHeadSlot
local CharacterMainHandSlot = _G.CharacterMainHandSlot
local CharacterSecondaryHandSlot = _G.CharacterSecondaryHandSlot
local CharacterStatsPane = _G.CharacterStatsPane
local HideUIPanel = _G.HideUIPanel
local hooksecurefunc = _G.hooksecurefunc

Module:SetScript("OnEvent", function()
	if CharacterFrame:IsShown() then
		HideUIPanel(CharacterFrame)
	end

	CharacterModelScene:DisableDrawLayer("BACKGROUND")
	CharacterModelScene:DisableDrawLayer("BORDER")
	CharacterModelScene:DisableDrawLayer("OVERLAY")

	CharacterModelScene:StripTextures(true)

	for _, slot in pairs({ PaperDollItemsFrame:GetChildren() }) do
		if slot:IsObjectType("Button") or slot:IsObjectType("ItemButton") then
			slot:StripTextures()
			slot:SetSize(37, 37)
		end
	end

	do
		CharacterHeadSlot:SetPoint("TOPLEFT", CharacterFrame.Inset, "TOPLEFT", 6, -6)
		CharacterHandsSlot:SetPoint("TOPRIGHT", CharacterFrame.Inset, "TOPRIGHT", -6, -6)
		CharacterMainHandSlot:SetPoint("BOTTOMLEFT", CharacterFrame.Inset, "BOTTOMLEFT", 176, 5)
		CharacterSecondaryHandSlot:ClearAllPoints()
		CharacterSecondaryHandSlot:SetPoint("BOTTOMRIGHT", CharacterFrame.Inset, "BOTTOMRIGHT", -176, 5)

		CharacterModelScene:SetSize(0, 0)
		CharacterModelScene:ClearAllPoints()
		CharacterModelScene:SetPoint("TOPLEFT", CharacterFrame.Inset, 0, 0)
		CharacterModelScene:SetPoint("BOTTOMRIGHT", CharacterFrame.Inset, 0, 20)
	end

	hooksecurefunc("CharacterFrame_Expand", function()
		CharacterFrame:SetSize(640, 431) -- 540 + 100, 424 + 7
		CharacterFrame.Inset:SetPoint("BOTTOMRIGHT", CharacterFrame, "BOTTOMLEFT", 432, 4)

		CharacterFrame.Inset.Bg:SetTexture("Interface\\DressUpFrame\\DressingRoom" .. select(2, UnitClass("player")))
		CharacterFrame.Inset.Bg:SetTexCoord(0.00195312, 0.935547, 0.00195312, 0.978516)
		CharacterFrame.Inset.Bg:SetHorizTile(false)
		CharacterFrame.Inset.Bg:SetVertTile(false)
	end)

	hooksecurefunc("CharacterFrame_Collapse", function()
		CharacterFrame:SetHeight(424)
		CharacterFrame.Inset:SetPoint("BOTTOMRIGHT", CharacterFrame, "BOTTOMLEFT", 332, 4)

		CharacterFrame.Inset.Bg:SetTexture("Interface\\FrameGeneral\\UI-Background-Marble", "REPEAT", "REPEAT")
		CharacterFrame.Inset.Bg:SetTexCoord(0, 1, 0, 1)
		CharacterFrame.Inset.Bg:SetHorizTile(true)
		CharacterFrame.Inset.Bg:SetVertTile(true)
	end)

	local CharItemLvLValue = CharacterStatsPane.ItemLevelFrame.Value
	CharItemLvLValue:SetFont(select(1, CharItemLvLValue:GetFont()), 20, select(3, ""))
	CharItemLvLValue:SetShadowOffset(1, -1)

	-- Titles
	hooksecurefunc(PaperDollFrame.TitleManagerPane.ScrollBox, "Update", function(self)
		for i = 1, self.ScrollTarget:GetNumChildren() do
			local child = select(i, self.ScrollTarget:GetChildren())
			if not child.styled then
				child:DisableDrawLayer("BACKGROUND")
				child.styled = true
			end
		end
	end)

	CharacterStatsPane.ClassBackground:ClearAllPoints()
	CharacterStatsPane.ClassBackground:SetHeight(CharacterStatsPane.ClassBackground:GetHeight() + 6)
	CharacterStatsPane.ClassBackground:SetParent(CharacterFrameInsetRight)
	CharacterStatsPane.ClassBackground:SetPoint("CENTER")
end)
