RollFor = RollFor or {}
local m = RollFor

if m.SoftResDataTransformer then return end

local M = {}

local make_roller = m.Types.make_roller

---@class RaidResData
---@field metadata RaidResMetadata
---@field hardreserves RaidResHardRessedItem[]
---@field softreserves RaidResSoftResEntry[]

---@class RaidResMetadata
---@field id string -- The id from the url.
---@field instance number -- Internal RaidRes' id.
---@field instances string[] -- Instance names.
---@field origin "raidres"

---@class RaidResHardRessedItem
---@field id number
---@field quality ItemQuality

---@class RaidResSoftResEntry
---@field name string -- Player name.
---@field role string
---@field items RaidResSoftRessedItem[]

---@class RaidResSoftRessedItem
---@field id number
---@field quality ItemQuality
---@field sr_plus number
---@field srPlus nil|number|{value: number, isValid: boolean}

---@class SoftRessedItem
---@field rollers Roller[]
---@field quality number

---@class HardRessedItem
---@field quality number

---@alias SoftResData table<ItemId, SoftRessedItem>
---@alias HardResData table<ItemId, HardRessedItem>

local function extract_sr_plus( item )
  -- Old raidres.fly.dev format: flat string or number
  if type( item.sr_plus ) == "string" or type( item.sr_plus ) == "number" then
    return tonumber( item.sr_plus )
  end

  -- New raidres.top format: camelCase field, possibly nested {value, isValid}
  if type( item.srPlus ) == "string" or type( item.srPlus ) == "number" then
    return tonumber( item.srPlus )
  end
  if type( item.srPlus ) == "table" and item.srPlus.value then
    -- raidres.top only exports valid entries once at least one reservation
    -- is validated, but leaves the pre-validation fallback case undocumented.
    -- Don't award an SR+ bonus that's explicitly flagged invalid.
    if item.srPlus.isValid == false then
      return nil
    end
    return tonumber( item.srPlus.value )
  end

  -- Fallback: old field as fallback-table (unlikely but defensive)
  if type( item.sr_plus ) == "table" and item.sr_plus.value then
    if item.sr_plus.isValid == false then
      return nil
    end
    return tonumber( item.sr_plus.value )
  end

  return nil
end

---@param data RaidResData
---@return SoftResData
---@return HardResData
function M.transform( data )
  local sr_result = {}
  local hr_result = {}
  local hard_reserves = data.hardreserves or {}
  local soft_reserves = data.softreserves or {}

  m.raid_id = data.metadata and data.metadata.id or nil

  local function find_roller( roller_name, rollers )
    for _, roller in ipairs( rollers ) do
      if roller.name == roller_name then
        return roller
      end
    end
  end

  for _, sr in ipairs( soft_reserves or {} ) do
    local roller_name = sr.name
    local roller_role = sr.role
    local item_ids = sr.items or {}

    for _, item in ipairs( item_ids ) do
      local item_id = item.id

      if item_id then
        sr_result[ item_id ] = sr_result[ item_id ] or {
          quality = item.quality,
          rollers = {}
        }

        local roller = find_roller( roller_name, sr_result[ item_id ].rollers )

        if not roller then
          roller = make_roller( roller_name, 1 )
          roller.sr_plus = extract_sr_plus( item )
          roller.role = roller_role
          table.insert( sr_result[ item_id ].rollers, roller )
        else
          roller.rolls = roller.rolls + 1
        end
      end
    end
  end

  for _, item in ipairs( hard_reserves or {} ) do
    local item_id = item.id

    if item_id then
      hr_result[ item_id ] = {
        quality = item.quality
      }
    end
  end

  return sr_result, hr_result
end

m.SoftResDataTransformer = M
return M
