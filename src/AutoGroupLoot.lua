RollFor = RollFor or {}
local m = RollFor

if m.AutoGroupLoot then return end

local M = {}

local getn = m.getn

---@class AutoGroupLoot
---@field on_loot_opened fun()
---@field on_loot_slot_cleared fun()
---@field on_loot_closed fun()

---@param loot_list LootList
---@param config Config
---@param boss_list BossList
---@param player_info PlayerInfo
---@param rolling_logic RollingLogic?
function M.new( loot_list, config, boss_list, player_info, rolling_logic )
  local m_is_boss = false
  local m_pending = false

  local function is_a_boss( name )
    if not name then return false end
    local zone_name = m.api.GetRealZoneText()
    local bosses = boss_list[ zone_name ] or {}
    return m.table_contains_value( bosses, name )
  end

  local function safe_set_group_loot()
    if not config.auto_group_loot or not config.auto_group_loot() then return end
    if not m.is_master_loot() or not player_info.is_leader() then return end

    -- Safety: NEVER call SetLootMethod while loot window is open!
    -- In WoW 1.12, calling SetLootMethod resets the loot session on the server
    -- and forcefully closes the loot window for anyone looting.
    if loot_list.is_looting() then
      m_pending = true
      return
    end

    -- Safety: Don't change loot method if rolling is in progress
    if rolling_logic and rolling_logic.is_rolling() then
      m_pending = true
      return
    end

    m.api.SetLootMethod( "group" )
    m_is_boss = false
    m_pending = false
  end

  local function on_loot_opened()
    local target_name = m.target_name()
    m_is_boss = is_a_boss( target_name )

    -- Fallback: If player had corpse untargeted when opening, check if items are flagged boss loot
    if not m_is_boss then
      for _, item in ipairs( loot_list.get_items() ) do
        if item.is_boss_loot then
          m_is_boss = true
          break
        end
      end
    end

    if m_is_boss and getn( loot_list.get_items() ) == 0 then
      m_pending = true
    end
  end

  local function on_loot_slot_cleared()
    if not m_is_boss then return end

    if getn( loot_list.get_items() ) == 0 then
      m_pending = true
      safe_set_group_loot()
    end
  end

  local function on_loot_closed()
    if m_pending then
      safe_set_group_loot()
    end
  end

  ---@type AutoGroupLoot
  return {
    on_loot_opened = on_loot_opened,
    on_loot_slot_cleared = on_loot_slot_cleared,
    on_loot_closed = on_loot_closed
  }
end

m.AutoGroupLoot = M
return M
