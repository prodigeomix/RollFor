package.path = "./?.lua;./test/?.lua;" .. package.path .. ";../?.lua;../RollFor/?.lua;../RollFor/libs/?.lua;../RollFor/libs/vanilla/LibStub/?.lua"

local u = require( "test/utils" )
local lu, eq = u.luaunit( "assertEquals" )

require( "src/bcc/compat" )
local m = u.modules()
u.mock_wow_api()

require( "src/BossList" )
require( "src/ItemUtils" )
local AutoGroupLoot = require( "src/AutoGroupLoot" )

AutoGroupLootSpec = {}

local function mock_loot_list( items )
  local is_looting_val = false
  return {
    get_items = function() return items end,
    is_looting = function() return is_looting_val end,
    set_looting = function( val ) is_looting_val = val end
  }
end

local function mock_config()
  return {
    auto_group_loot = function() return true end
  }
end

local function mock_player_info()
  return {
    is_leader = function() return true end
  }
end

local function mock_roll_controller()
  local listeners = {}
  return {
    subscribe = function( event, callback )
      listeners[ event ] = listeners[ event ] or {}
      table.insert( listeners[ event ], callback )
    end,
    fire = function( event, data )
      for _, cb in ipairs( listeners[ event ] or {} ) do
        cb( data )
      end
    end
  }
end

local function mock_softres( reserved_item_ids )
  local reserved = {}
  for _, id in ipairs( reserved_item_ids ) do
    reserved[ id ] = { { name = "SomePlayer", rolls = 1 } }
  end

  return {
    get = function( id )
      return reserved[ id ] or {}
    end,
    is_item_hardressed = function( id )
      return false
    end
  }
end

function AutoGroupLootSpec:should_detect_broodcommander_axelus_as_boss_and_kill()
  local loot_list = mock_loot_list( {} )
  local config = mock_config()
  local player_info = mock_player_info()
  local rc = mock_roll_controller()

  m.api.GetRealZoneText = function() return "Onyxia's Lair" end
  m.target_name = function() return "Broodcommander Axelus" end
  m.target_dead = function() return false end

  local agl = AutoGroupLoot.new( loot_list, config, m.BossList.zones, player_info, rc, nil, nil, nil )

  agl.on_combat_start()
  agl.on_hostile_death( "Broodcommander Axelus dies." )

  -- Opening loot on killed Axelus sets m_looting_boss
  local loot_method_set = nil
  m.api.SetLootMethod = function( method ) loot_method_set = method end
  m.api.GetLootThreshold = function() return 2 end
  m.is_master_loot = function() return true end

  agl.on_loot_opened()
  -- Corpse was empty, so on loot closed it safely reverts
  agl.on_loot_closed()

  eq( loot_method_set, "group" )
end

function AutoGroupLootSpec:should_track_soft_reserved_rare_item_and_delay_group_loot()
  local epic_helm = { id = 16921, quality = 4, type = "Item", bind = m.ItemUtils.BindType.BindOnPickup }
  local rare_backpack = { id = 17966, quality = 3, type = "Item", bind = m.ItemUtils.BindType.None }

  local loot_list = mock_loot_list( { epic_helm, rare_backpack } )
  local config = mock_config()
  local player_info = mock_player_info()
  local rc = mock_roll_controller()
  local softres = mock_softres( { 17966 } ) -- Backpack is soft-reserved!

  local loot_method_set = nil
  m.api.SetLootMethod = function( method ) loot_method_set = method end
  m.api.GetLootThreshold = function() return 4 end -- Master loot is Epic (4)
  m.api.GetRealZoneText = function() return "Onyxia's Lair" end
  m.target_name = function() return "Onyxia" end
  m.target_dead = function() return true end
  m.is_master_loot = function() return true end

  local agl = AutoGroupLoot.new( loot_list, config, m.BossList.zones, player_info, rc, nil, nil, softres )

  agl.on_combat_start()
  agl.on_hostile_death( "Onyxia dies." )
  agl.on_loot_opened()

  -- Award the Epic helm
  rc.fire( "loot_awarded", { item_id = 16921 } )

  -- MUST NOT revert yet because rare_backpack (17966) is soft-reserved!
  eq( loot_method_set, nil )

  -- Award the rare backpack
  rc.fire( "loot_awarded", { item_id = 17966 } )

  -- NOW all items are awarded, must revert to group loot!
  eq( loot_method_set, "group" )
end

function AutoGroupLootSpec:should_not_track_unreserved_rare_item_when_threshold_is_epic()
  local epic_helm = { id = 16921, quality = 4, type = "Item", bind = m.ItemUtils.BindType.BindOnPickup }
  local unreserved_rare = { id = 99999, quality = 3, type = "Item", bind = m.ItemUtils.BindType.None }

  local loot_list = mock_loot_list( { epic_helm, unreserved_rare } )
  local config = mock_config()
  local player_info = mock_player_info()
  local rc = mock_roll_controller()
  local softres = mock_softres( {} ) -- Nothing soft-reserved

  local loot_method_set = nil
  m.api.SetLootMethod = function( method ) loot_method_set = method end
  m.api.GetLootThreshold = function() return 4 end -- Master loot is Epic (4)
  m.api.GetRealZoneText = function() return "Onyxia's Lair" end
  m.target_name = function() return "Onyxia" end
  m.target_dead = function() return true end
  m.is_master_loot = function() return true end

  local agl = AutoGroupLoot.new( loot_list, config, m.BossList.zones, player_info, rc, nil, nil, softres )

  agl.on_combat_start()
  agl.on_hostile_death( "Onyxia dies." )
  agl.on_loot_opened()

  -- Award the Epic helm
  rc.fire( "loot_awarded", { item_id = 16921 } )

  -- Since unreserved_rare is below threshold and not soft-reserved, group loot is safely reverted
  eq( loot_method_set, "group" )
end

os.exit( lu.LuaUnit.run( "-o", "text", "-v", "-T", "Spec", "-m", "should" ) )
