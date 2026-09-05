RollFor = RollFor or {}
local m = RollFor

if m.AutoMasterLoot then return end

local M = {}

---@class AutoMasterLoot
---@field on_player_target_changed fun( arg1: any? )
---@field on_combat_start fun()

---@param config Config
---@param boss_list BossList
---@param player_info PlayerInfo
function M.new( config, boss_list, player_info )
  local function check_and_set_master_loot( arg1 )
    if not config.auto_master_loot() then return end

    local target_name = m.target_name()
    if not target_name or m.target_dead() then return end

    local zone_name = m.api.GetRealZoneText()
    local bosses = boss_list[ zone_name ] or {}
    local is_a_boss = m.table_contains_value( bosses, target_name )

    -- On Turtle, PLAYER_TARGET_CHANGED gets emitted with some float number as an argument automatically.
    -- We don't want to respond to these scanner events.
    local auto_target = tonumber( arg1 ) and tonumber( arg1 ) ~= math.floor( arg1 )
    local valid_target = m.api.UnitExists( "target" ) and not m.api.UnitIsPlayer( "target" )

    if is_a_boss and valid_target and not auto_target and not m.is_master_loot() and player_info.is_leader() then
      m.api.SetLootMethod( "master", player_info.get_name() )
    end
  end

  local function on_player_target_changed( arg1 )
    check_and_set_master_loot( arg1 )
  end

  local function on_combat_start()
    check_and_set_master_loot( nil )
  end

  return {
    on_player_target_changed = on_player_target_changed,
    on_combat_start = on_combat_start
  }
end

m.AutoMasterLoot = M
return M
