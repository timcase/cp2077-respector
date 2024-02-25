local mod = ...
local TweakDb = mod.require('mod/helpers/TweakDb')

local Tweaker = {}
Tweaker.__index = Tweaker

function Tweaker:new(respector)
  local this = { respector = respector }

  setmetatable(this, self)

  return this
end

function Tweaker:addPack(packSpec, cheatMode)
  local tweakDb = TweakDb:new(true)

  local itemSpecs = {}
  local recipeSpecs = {}
  local vehicleSpecs = {}

  for itemKey, itemMeta in tweakDb:filter(self:toPackCriteria(packSpec)) do
    if TweakDb.isRealKey(itemKey) then
      if packSpec.type == 'Recipe' then
        table.insert(recipeSpecs, itemMeta.id)
      elseif itemMeta.kind == 'Vehicle' then
        table.insert(vehicleSpecs, itemMeta.id)
      else
        local itemSpec = {}

        itemSpec.id = itemMeta.id

        if not itemMeta.quality then
          if packSpec.upgrade then
            itemSpec.upgrade = packSpec.upgrade
          elseif itemMeta.max then
            itemSpec.upgrade = itemMeta.max
          end
        end

        if itemMeta.kind == 'Clothing' then
          itemSpec.slots = 'max'
        end

        itemSpec.quest = false

        table.insert(itemSpecs, itemSpec)
      end
    end
  end

  tweakDb:unload()

  local specData = {
    Backpack = itemSpecs,
    Vehicles = vehicleSpecs,
    Crafting = {
      Recipes = recipeSpecs
    }
  }

  local specOptions = {
    cheat = cheatMode
  }

  self.respector:execSpec(specData, specOptions)
end

function Tweaker:getPackSize(packSpec)
  local tweakDb = TweakDb:new(true)

  local packSize = 0

  for itemKey, _ in tweakDb:filter(self:toPackCriteria(packSpec)) do
    if TweakDb.isRealKey(itemKey) then
      packSize = packSize + 1
    end
  end

  tweakDb:unload()

  return packSize
end

function Tweaker:toPackCriteria(packSpec)
  if packSpec.kind == 'Recipe' then
    return {
      kind = { 'Weapon', 'Clothing', 'Cyberware', 'Mod', 'Grenade', 'Consumable', 'Quickhack', 'Ammo' }
    }
  end

  return {
    kind = packSpec.kind,
    group = packSpec.group,
    group2 = packSpec.group2,
    iconic = packSpec.iconic,
    tag = packSpec.tag,
    set = packSpec.set,
    quality = packSpec.quality,
    --craft = packSpec.craft,
  }
end

function Tweaker:addItem(itemSpec, cheatMode)
  self.respector:execSpec({ Inventory = { itemSpec } }, { cheat = cheatMode })
end

function Tweaker:addRecipe(itemId)
  self.respector:usingModule('crafting', function(crafting)
    crafting:addRecipe(itemId)
  end)
end

function Tweaker:addRecipes(itemIds)
  self.respector:usingModule('crafting', function(crafting)
    crafting:addRecipes(itemIds)
  end)
end

function Tweaker:getResource(resourceId)
  resourceId = TweakDb.toItemId(resourceId, false)

  return Game.GetTransactionSystem():GetItemQuantity(Game.GetPlayer(), resourceId)
end

function Tweaker:addResource(resourceId, resourceAmount)
  resourceId = TweakDb.toItemId(resourceId, false)

  Game.GetTransactionSystem():GiveItem(Game.GetPlayer(), resourceId, resourceAmount)
end

function Tweaker:hasVehicle(vehicleId)
  return self.respector:usingModule('transport', function(transport)
    return transport:isVehicleUnlocked(vehicleId)
  end)
end

function Tweaker:canHaveVehicle(vehicleId)
  return self.respector:usingModule('transport', function(transport)
    return transport:isVehicleUnlockable(vehicleId)
  end)
end

function Tweaker:addVehicle(vehicleId)
  self.respector:usingModule('transport', function(transport)
    transport:unlockVehicle(vehicleId)
  end)
end

function Tweaker:spawnVehicle(vehicleId)
  self:execHack('SpawnVehicle', vehicleId)
end

function Tweaker:getFact(factName)
  return Game.GetQuestsSystem():GetFactStr(factName) == 1
end

function Tweaker:setFact(factName, factState)
  Game.GetQuestsSystem():SetFactStr(factName, factState and 1 or 0)
end

function Tweaker:execHack(tweakName, ...)
  local tweakFunc = mod.load('mod/hacks/' .. tweakName)

  if type(tweakFunc) == 'function' then
    tweakFunc(select(1, ...))
  end
end

return Tweaker