-- -------------------------------------------------------------------------- --
-- Base Directory
-- -------------------------------------------------------------------------- --
-- Can be an absolute path or relative to the CET mods directory.
-- Change it if you renamed the directory of the mod.
-- -------------------------------------------------------------------------- --

local baseDir = 'plugins/cyber_engine_tweaks/mods/respector'

-- -------------------------------------------------------------------------- --
-- Debug Mode
-- -------------------------------------------------------------------------- --
-- Enables debug output in the console.
-- -------------------------------------------------------------------------- --

local debugMode = false

-- -------------------------------------------------------------------------- --
-- Developer Mode
-- -------------------------------------------------------------------------- --
-- 1. Resets Lua package cache forcing require() to always read the source.
-- 2. Recalculates hashes of known TweakDB names on every mod load.
-- 3. Recompiles the samples on every mod load.
-- 4. Recreates default confing file on every mod load.
-- 5. Enables Developer menu in th GUI.
-- -------------------------------------------------------------------------- --

local devMode = false

-- -------------------------------------------------------------------------- --

local corePath = baseDir .. '/mod/mod'

if package.loaded[corePath] ~= nil then
	package.loaded[corePath] = nil

	if devMode then
		package.loaded[corePath .. '-state'] = nil
	end

	if debugMode then
		print(('[DEBUG] Respector: Reloaded module %q.'):format(corePath))
	end
end

local api = {}
local mod = require(corePath)

mod.init(devMode, debugMode)

if devMode then
	local Compiler = mod.require('mod/Compiler')
	local compiler = Compiler:new()

	compiler:run()
end

local Respector = mod.require('mod/Respector')
local respector = Respector:new()

if mod.config.useModApi or mod.config.useGlobalApi then
	if mod.debug then
		print(('[DEBUG] Respector: Initializing CLI...'))
	end

	local cli = mod.require('mod/ui/cli')

	cli.init(respector)

	if mod.config.useGlobalApi then
		cli.registerGlobalApi()
	else
		cli.unregisterGlobalApi()
	end

	if mod.config.useModApi then
		api = cli.getModApi()
	end
end

if mod.config.useGui then
	if mod.debug then
		print(('[DEBUG] Respector: Initializing GUI...'))
	end

	local gui = mod.require('mod/ui/gui')

	registerForEvent('onInit', function()
		gui.init(respector)
	end)

	registerForEvent('onDraw', function()
		gui.onDrawEvent()
	end)

	registerForEvent('onConsoleOpen', function()
		gui.onConsoleOpenEvent()
	end)

	registerForEvent('onConsoleClose', function()
		gui.onConsoleCloseEvent()
	end)

	registerForEvent('onUpdate', function(delta)
		mod.onUpdateEvent(delta)
		gui.onUpdateEvent()
	end)
else
	registerForEvent('onUpdate', function(delta)
		mod.onUpdateEvent(delta)
	end)
end

print(('Respector v%s %s.'):format(respector.version, (mod.start and 'loaded' or 'reloaded')))

if mod.config.useGlobalApi then
	print(('Respector: Global API enabled.'))
end

if mod.config.useGui then
	print(('Respector: Console GUI enabled.'))
end

if mod.env.is183() then
	print(('Respector: The mod\'s functions are limited and not guaranteed because Cyber Engine Tweaks 1.8.3 or lower is used.'))
	print(('Respector: It\'s recommended to upgrade your Cyber Engine Tweaks to version 1.8.4 or higher.'))
end

return api