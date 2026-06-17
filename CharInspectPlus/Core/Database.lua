--[[
	CharInspectPlus - Database
	-------------------------------------------------------------------------
	Lightweight saved-variable manager with per-character profile support.
--]]

local _, ns = ...
local C, F = ns.C, ns.F

ns.defaults = {
	profile = {},
	global = {},
}

function ns:RegisterDefaults(defaults, scope)
	scope = scope or "profile"
	F.CopyDefaults(defaults, ns.defaults[scope])
end

local DB_SCHEMA_VERSION = 1

local migrations = {}

local function MigrateDatabase(root)
	local version = root.schemaVersion or 1
	for v = version + 1, DB_SCHEMA_VERSION do
		local step = migrations[v]
		if step then
			step(root)
		end
	end
	root.schemaVersion = DB_SCHEMA_VERSION
end

function ns:SetProfile(profileName)
	local root = _G.CharInspectPlusDB
	root.profileKeys[C.Player.key] = profileName
	root.profiles[profileName] = root.profiles[profileName] or {}

	ns.db = F.CopyDefaults(ns.defaults.profile, root.profiles[profileName])
	ns.profileName = profileName

	if ns.OnProfileChanged then
		ns:OnProfileChanged(profileName)
	end
end

function ns:ResetProfile()
	local root = _G.CharInspectPlusDB
	root.profiles[ns.profileName] = {}
	ns.db = F.CopyDefaults(ns.defaults.profile, root.profiles[ns.profileName])

	if ns.OnProfileChanged then
		ns:OnProfileChanged(ns.profileName)
	end
	return true
end

function ns:SetupDatabase()
	local root = _G.CharInspectPlusDB or {}
	_G.CharInspectPlusDB = root
	root.profiles = root.profiles or {}
	root.profileKeys = root.profileKeys or {}
	root.global = F.CopyDefaults(ns.defaults.global, root.global)

	MigrateDatabase(root)

	local profileName = root.profileKeys[C.Player.key] or "Default"
	ns.global = root.global
	ns:SetProfile(profileName)
end
