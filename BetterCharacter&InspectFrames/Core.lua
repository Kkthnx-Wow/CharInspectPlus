local UIFrameHider = CreateFrame("Frame", "Kkthnx_UIFrameHider", UIParent, "SecureHandlerAttributeTemplate")
UIFrameHider:Hide()
UIFrameHider:SetPoint("TOPLEFT", 0, 0)
UIFrameHider:SetPoint("BOTTOMRIGHT", 0, 0)
RegisterAttributeDriver(UIFrameHider, "state-visibility", "hide")

local PetBattleHider = CreateFrame("Frame", "Kkthnx_PetBattleHider", UIParent, "SecureHandlerStateTemplate")
PetBattleHider:SetAllPoints()
PetBattleHider:SetFrameStrata("LOW")
RegisterStateDriver(PetBattleHider, "visibility", "[petbattle] hide; show")

local function Kill(object)
	if object.UnregisterAllEvents then
		object:UnregisterAllEvents()
		object:SetParent(UIFrameHider)
	else
		object.Show = object.Hide
	end
	object:Hide()
end

local blizzTextures = {
	"Inset",
	"inset",
	"InsetFrame",
	"LeftInset",
	"RightInset",
	"NineSlice",
	"BG",
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
}

local function StripTextures(object, kill)
	local frameName = object.GetName and object:GetName()
	for _, texture in pairs(blizzTextures) do
		local blizzFrame = object[texture] or (frameName and _G[frameName .. texture])
		if blizzFrame then
			StripTextures(blizzFrame, kill)
		end
	end

	if object.GetNumRegions then
		for i = 1, object:GetNumRegions() do
			local region = select(i, object:GetRegions())
			if region and region.IsObjectType and region:IsObjectType("Texture") then
				if kill and type(kill) == "boolean" then
					region:Kill()
				elseif tonumber(kill) then
					if kill == 0 then
						region:SetAlpha(0)
					elseif i ~= kill then
						region:SetTexture("")
					end
				else
					region:SetTexture("")
				end
			end
		end
	end
end

local function addapi(object)
	local mt = getmetatable(object).__index

	if not object.Kill then
		mt.Kill = Kill
	end

	if not object.StripTextures then
		mt.StripTextures = StripTextures
	end
end

local handled = { Frame = true }
local object = CreateFrame("Frame")
addapi(object)
addapi(object:CreateTexture())
addapi(object:CreateFontString())
addapi(object:CreateMaskTexture())

object = EnumerateFrames()
while object do
	if not object:IsForbidden() and not handled[object:GetObjectType()] then
		addapi(object)
		handled[object:GetObjectType()] = true
	end

	object = EnumerateFrames(object)
end
