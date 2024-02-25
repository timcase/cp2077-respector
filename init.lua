-- -------------------------------------------------------------------------- --
-- Cyber Engine Tweaks Version
-- -------------------------------------------------------------------------- --

local cetVer = tonumber((GetVersion():gsub('^v(%d+)%.(%d+)%.(%d+)(.*)', function(major, minor, patch, wip)
  return ('%d.%02d%02d%d'):format(major, minor, patch, (wip == '' and 0 or 1))
end))) or 1.21

-- -------------------------------------------------------------------------- --
-- Debug Mode
-- -------------------------------------------------------------------------- --
-- Enables debug output in the console.
-- -------------------------------------------------------------------------- --

local debugMode = true
print(('[DEBUG] Respector: Debug mode is %s.'):format(debugMode and 'enabled' or 'disabled'))

-- -------------------------------------------------------------------------- --
-- Developer Mode
-- -------------------------------------------------------------------------- --
-- 1. Resets Lua package cache forcing require() to always read the source.
-- 2. Recalculates hashes of known TweakDBIDs on every mod load.
-- 3. Collects localized name and description of TweakDB records.
-- 4. Recompiles the samples on every mod load.
-- 5. Recreates default confing file on every mod load.
-- -------------------------------------------------------------------------- --

local devMode = true
print(('[DEBUG] Respector: Developer mode is %s.'):format(devMode and 'enabled' or 'disabled'))

-- -------------------------------------------------------------------------- --

local coreReq = 'mod.lua'

if cetVer <= 1.0906 then
  coreReq = 'plugins/cyber_engine_tweaks/mods/respector/mod'

  if package.loaded[coreReq] ~= nil then
    package.loaded[coreReq] = nil

    if devMode then
      package.loaded[coreReq .. '-state'] = nil
    end

    if debugMode then
      print(('[DEBUG] Respector: Reloaded module %q.'):format(coreReq))
    end
  end
end

local api = {}
local mod = require(coreReq)

mod.init(debugMode)

local Respector = mod.require('mod/Respector')
local respector = Respector:new()

local Tweaker = mod.require('mod/Tweaker')
local tweaker = Tweaker:new(respector)

if mod.config.useModApi or mod.config.useGlobalApi then
  if mod.debug then
    print(('[DEBUG] Respector: Initializing CLI...'))
  end

  local cli = mod.require('mod/ui/cli')

  cli.init(respector, tweaker)

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
    if devMode then
      local Compiler = mod.require('mod/Compiler')
      local compiler = Compiler:new()

      compiler:run()
    end

    gui.init(respector, tweaker)
  end)

  registerForEvent('onOverlayOpen', gui.onOverlayOpen)
  registerForEvent('onOverlayClose', gui.onOverlayClose)

  registerForEvent('onDraw', gui.onDrawEvent)
end

registerForEvent('onUpdate', mod.onUpdateEvent)

--print(('Respector v%s loaded.'):format(respector.version))

return api