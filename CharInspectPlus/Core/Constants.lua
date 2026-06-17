--[[
	CharInspectPlus - Constants
	-------------------------------------------------------------------------
	Static session data: client info, player key, brand palette.
--]]

local _, ns = ...
local C = ns.C

local UnitName = UnitName
local UnitClass = UnitClass
local UnitLevel = UnitLevel
local UnitFactionGroup = UnitFactionGroup
local GetRealmName = GetRealmName
local GetLocale = GetLocale
local GetBuildInfo = GetBuildInfo

do
	local version, build, _, interface = GetBuildInfo()
	C.Client = {
		version = version,
		build = build,
		interface = interface,
		locale = GetLocale(),
		isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE,
	}
end

do
	local className, classFile = UnitClass("player")
	C.Player = {
		name = UnitName("player"),
		realm = GetRealmName(),
		level = UnitLevel("player"),
		class = classFile,
		className = className,
		faction = UnitFactionGroup("player"),
	}
	C.Player.key = C.Player.name .. " - " .. C.Player.realm
end

local classColor = (_G["CUSTOM_CLASS_COLORS"] or RAID_CLASS_COLORS)[C.Player.class]
C.ClassColor = { classColor.r, classColor.g, classColor.b }

C.Colors = {
	red = { 0.90, 0.30, 0.30 },
	green = { 0.40, 0.78, 0.40 },
	white = { 1.00, 1.00, 1.00 },
	brand = { 0.40, 0.62, 1.00 }, -- #669DFF
	class = C.ClassColor,
}

C.BrandHex = ("ff%02x%02x%02x"):format(C.Colors.brand[1] * 255, C.Colors.brand[2] * 255, C.Colors.brand[3] * 255)

C.Media = {
	Textures = {
		blank = "Interface\\Buttons\\WHITE8x8",
		marble = "Interface\\FrameGeneral\\UI-Background-Marble",
	},
}
