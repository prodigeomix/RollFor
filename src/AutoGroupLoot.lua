RollFor = RollFor or {}
local m = RollFor

if m.AutoGroupLoot then return end

local M = {}

local getn = m.getn

---@class AutoGroupLoot
---@field on_loot_opened fun()
---@field on_loot_slot_cleared fun( slot: number? )
---@field on_loot_closed fun()
---@field on_combat_start fun()
---@field on_combat_end fun()
---@field on_player_target_changed fun()
---@field on_hostile_death fun( message: string )

---@param loot_list LootList
---@param config Config
---@param boss_list BossList
---@param player_info PlayerInfo
---@param roll_controller RollController?
---@param rolling_logic RollingLogic?
---@param chat Chat?
function M.new( loot_list, config, boss_list, player_info, roll_controller, rolling_logic, chat )
  local m_boss_encounter = false
  local m_boss_name = nil
  local m_boss_killed = false
  local m_looting_boss = false
  local m_boss_items = {}
  local m_pending_group_loot = false

  local function is_a_boss( name )
    if not name then return false end
    local zone_name = m.api.GetRealZoneText()
    local bosses = boss_list[ zone_name ] or {}
    return m.table_contains_value( bosses, name )
  end

  local function count_pending_items()
    local count = 0
    for _, c in pairs( m_boss_items ) do
      count = count + c
    end
    return count
  end

  local function reset_state()
    m_boss_encounter = false
    m_boss_name = nil
    m_boss_killed = false
    m_looting_boss = false
    m_boss_items = {}
    m_pending_group_loot = false
  end

  local function safe_set_group_loot( reason )
    if not config.auto_group_loot() then return end
    if not m.is_master_loot() or not player_info.is_leader() then return end

    -- Safety: NEVER call SetLootMethod while loot window is open!
    -- In WoW 1.12, calling SetLootMethod resets the loot session on the server
    -- and forcefully closes the loot window for anyone looting.
    if loot_list.is_looting() then
      m_pending_group_loot = true
      return
    end

    -- Safety: Don't change loot method if rolling is in progress
    if rolling_logic and rolling_logic.is_rolling() then
      m_pending_group_loot = true
      return
    end

    m.api.SetLootMethod( "group" )

    local message = reason or "All boss items assigned."
    if chat then
      chat.info( string.format( "%s Reverted loot to Group Loot.", message ) )
    else
      m.pretty_print( string.format( "%s Reverted loot to Group Loot.", message ) )
    end

    reset_state()
  end

  local function on_combat_start()
    local target_name = m.target_name()
    if target_name and is_a_boss( target_name ) and not m.target_dead() then
      m_boss_encounter = true
      m_boss_name = target_name
      m_boss_killed = false
      m_looting_boss = false
    end
  end

  local function on_player_target_changed()
    local target_name = m.target_name()
    if target_name and is_a_boss( target_name ) and not m.target_dead() then
      m_boss_encounter = true
      m_boss_name = target_name
      m_boss_killed = false
    end
  end

  local function on_hostile_death( message )
    if not message then return end
    for dead_unit in string.gmatch( message, "(.*) dies%." ) do
      if is_a_boss( dead_unit ) then
        m_boss_killed = true
        m_boss_name = dead_unit
      end
      return
    end
  end

  local function on_combat_end()
    -- Wipe / reset detection: engaged a boss, but boss did not die
    if m_boss_encounter and not m_boss_killed then
      safe_set_group_loot( "Boss encounter ended (wipe/reset)." )
      reset_state()
    end
  end

  local function on_loot_opened()
    local target_name = m.target_name()
    local corpse_is_boss = (target_name and is_a_boss( target_name )) or m_boss_killed

    -- Also check if items on the corpse are marked as boss loot or epic in raid
    if not corpse_is_boss then
      for _, item in ipairs( loot_list.get_items() ) do
        if item.is_boss_loot or (item.quality and item.quality >= 4) then
          corpse_is_boss = true
          break
        end
      end
    end

    if corpse_is_boss then
      m_looting_boss = true
      m_boss_items = {}
      local threshold = m.api.GetLootThreshold() or 2
      local found_items = false

      for _, item in ipairs( loot_list.get_items() ) do
        if item.type ~= "Coin" and item.id then
          -- Track items that are master looter quality (>= threshold or BoP)
          if (item.quality and item.quality >= threshold) or item.bind == m.ItemUtils.BindType.BindOnPickup then
            m_boss_items[ item.id ] = (m_boss_items[ item.id ] or 0) + 1
            found_items = true
          end
        end
      end

      -- If boss dropped no master loot items (e.g. only coin / trash)
      if not found_items then
        m_pending_group_loot = true
      end
    end
  end

  local function on_item_awarded( data )
    if not m_looting_boss then return end

    if data and data.item_id and m_boss_items[ data.item_id ] then
      m_boss_items[ data.item_id ] = m_boss_items[ data.item_id ] - 1
      if m_boss_items[ data.item_id ] <= 0 then
        m_boss_items[ data.item_id ] = nil
      end

      if count_pending_items() == 0 then
        m_pending_group_loot = true
        if not loot_list.is_looting() and not (rolling_logic and rolling_logic.is_rolling()) then
          safe_set_group_loot( "All boss items assigned." )
        end
      end
    end
  end

  local function on_loot_slot_cleared( slot )
    if not m_looting_boss then return end

    -- Check if all items are gone from corpse
    local remaining_items = loot_list.get_items()
    if getn( remaining_items ) == 0 then
      m_pending_group_loot = true
      if not loot_list.is_looting() and not (rolling_logic and rolling_logic.is_rolling()) then
        safe_set_group_loot( "All boss items looted." )
      end
    end
  end

  local function on_loot_closed()
    -- When the loot window closes:
    -- If all boss items are already assigned / cleared or corpse was empty:
    if m_pending_group_loot or (m_looting_boss and count_pending_items() == 0) then
      if not (rolling_logic and rolling_logic.is_rolling()) then
        safe_set_group_loot( "All boss items assigned." )
      end
    end
  end

  if roll_controller then
    roll_controller.subscribe( "loot_awarded", on_item_awarded )
  end

  ---@type AutoGroupLoot
  return {
    on_loot_opened = on_loot_opened,
    on_loot_slot_cleared = on_loot_slot_cleared,
    on_loot_closed = on_loot_closed,
    on_combat_start = on_combat_start,
    on_combat_end = on_combat_end,
    on_player_target_changed = on_player_target_changed,
    on_hostile_death = on_hostile_death
  }
end

m.AutoGroupLoot = M
return M
