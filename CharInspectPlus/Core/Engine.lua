--[[
	CharInspectPlus - Engine
	-------------------------------------------------------------------------
	Owns the addon namespace, module registry, shared event dispatcher, and
	load lifecycle. Every other file consumes `local addonName, ns = ...`.
--]]

local addonName, ns = ...

_G.CharInspectPlus = ns

local CreateFrame = CreateFrame
local IsLoggedIn = IsLoggedIn
local tinsert = table.insert
local C_AddOns = C_AddOns

ns.name = addonName
ns.title = C_AddOns.GetAddOnMetadata(addonName, "Title") or addonName
ns.version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "0.0.0"

ns.C = ns.C or {}
ns.F = ns.F or {}
ns.L = ns.L or setmetatable({}, {
	__index = function(_, key)
		return key
	end,
})

local modules = {}
local moduleByName = {}

ns.modules = modules

local moduleMeta = {}
moduleMeta.__index = moduleMeta

function moduleMeta:RegisterEvent(event, handler)
	handler = handler or self[event]
	if type(handler) == "string" then
		handler = self[handler]
	end
	assert(type(handler) == "function", ("CharInspectPlus: no handler for event '%s' on module '%s'"):format(event, self.name))

	ns:RegisterEvent(event, function(_, ...)
		handler(self, ...)
	end)
end

function moduleMeta:IsEnabled()
	if not ns.db then
		return false
	end
	local settings = self.dbKey and ns.db[self.dbKey]
	if settings and settings.enable ~= nil then
		return settings.enable
	end
	return true
end

function ns:NewModule(name, dbKey, opts)
	assert(not moduleByName[name], ("CharInspectPlus: module '%s' already exists"):format(name))

	local module = setmetatable({ name = name, dbKey = dbKey }, moduleMeta)
	if opts then
		module.group = opts.group
		module.title = opts.title
		module.order = opts.order
	end
	moduleByName[name] = module
	tinsert(modules, module)
	return module
end

function ns:GetModule(name)
	return moduleByName[name]
end

local eventFrame = CreateFrame("Frame", "CharInspectPlusEventFrame")
local eventCallbacks = {}

eventFrame:SetScript("OnEvent", function(_, event, ...)
	local callbacks = eventCallbacks[event]
	if not callbacks then
		return
	end
	for i = 1, #callbacks do
		local callback = callbacks[i]
		if callback then
			callback(event, ...)
		end
	end
end)

function ns:RegisterEvent(event, callback)
	local callbacks = eventCallbacks[event]
	if not callbacks then
		callbacks = {}
		eventCallbacks[event] = callbacks
		eventFrame:RegisterEvent(event)
	end
	for i = 1, #callbacks do
		if not callbacks[i] then
			callbacks[i] = callback
			return callback
		end
	end
	callbacks[#callbacks + 1] = callback
	return callback
end

function ns:UnregisterEvent(event, callback)
	local callbacks = eventCallbacks[event]
	if not callbacks then
		return
	end

	local anyLive = false
	for i = 1, #callbacks do
		if callbacks[i] == callback then
			callbacks[i] = false
		elseif callbacks[i] then
			anyLive = true
		end
	end

	if not anyLive then
		eventCallbacks[event] = nil
		eventFrame:UnregisterEvent(event)
	end
end

local signalCallbacks = {}

function ns:RegisterCallback(signal, callback, owner)
	local list = signalCallbacks[signal]
	if not list then
		list = {}
		signalCallbacks[signal] = list
	end
	list[#list + 1] = { callback, owner, type(callback) == "string" }
	return callback
end

function ns:TriggerCallback(signal, ...)
	local list = signalCallbacks[signal]
	if not list then
		return
	end
	for i = 1, #list do
		local cb = list[i]
		if cb then
			if cb[3] then
				cb[2][cb[1]](cb[2], ...)
			elseif cb[2] then
				cb[1](cb[2], ...)
			else
				cb[1](...)
			end
		end
	end
end

local initialized, enabled = false, false

local function RunCallback(module, method)
	local fn = module[method]
	if type(fn) ~= "function" then
		return
	end
	local ok, err = pcall(fn, module)
	if not ok then
		ns.F.Print("|cffff5555Error in", module.name, "(" .. method .. "):|r", err)
	end
end

local function Enable()
	if enabled or not initialized then
		return
	end
	enabled = true

	for i = 1, #modules do
		local module = modules[i]
		if module:IsEnabled() then
			RunCallback(module, "OnEnable")
		end
	end
end

local function Initialize()
	if initialized then
		return
	end
	initialized = true

	if ns.SetupDatabase then
		ns:SetupDatabase()
	end

	for i = 1, #modules do
		RunCallback(modules[i], "OnInitialize")
	end

	if IsLoggedIn() then
		Enable()
	end
end

local onAddonLoaded
onAddonLoaded = function(_, loadedAddon)
	if loadedAddon ~= addonName then
		return
	end
	ns:UnregisterEvent("ADDON_LOADED", onAddonLoaded)
	Initialize()
end

ns:RegisterEvent("ADDON_LOADED", onAddonLoaded)
ns:RegisterEvent("PLAYER_LOGIN", Enable)
