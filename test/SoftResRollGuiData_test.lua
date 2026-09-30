package.path = "./?.lua;./test/?.lua;" .. package.path .. ";../?.lua;../RollFor/?.lua;../RollFor/libs/?.lua;../RollFor/libs/vanilla/LibStub/?.lua"

local u = require( "test/utils" )
local lu, eq = u.luaunit( "assertEquals" )
local m = require( "src/modules" )
local types = require( "src/Types" )
local mod = require( "src/SoftResRollGuiData" )

local SR = types.RollType.SoftRes

SoftResRollGuiDataSpec = {}

local function p( player_name, player_class )
  return { name = player_name, class = player_class }
end

local function mock_group_roster( players )
  return {
    find_player = function( player_name )
      for _, player in ipairs( players ) do
        if player.name == player_name then return player end
      end
      return nil
    end
  }
end

local function mock_softres( item_id, rollers )
  return {
    get = function( id )
      if id == item_id then return rollers end
      return {}
    end
  }
end

function SoftResRollGuiDataSpec:should_generate_gui_data_when_all_players_present()
  -- Given
  local group_roster = mock_group_roster( { p( "Carbon", "Priest" ), p( "Bik", "Warrior" ) } )
  local softres = mock_softres( 30017, {
    { name = "Bik", rolls = 1 },
    { name = "Carbon", rolls = 1 }
  } )

  local gui_data = mod.new( softres, group_roster )
  gui_data.start( 30017 )

  -- When
  local result = gui_data.get()

  -- Then
  lu.assertEquals( #result, 2 )
  lu.assertEquals( result[ 1 ].player_name, "Bik" )
  lu.assertEquals( result[ 1 ].player_class, "Warrior" )
  lu.assertEquals( result[ 2 ].player_name, "Carbon" )
  lu.assertEquals( result[ 2 ].player_class, "Priest" )
end

function SoftResRollGuiDataSpec:should_not_crash_when_sr_player_is_absent_from_group()
  -- Given: Axtrox and Remorph soft-reserved, but Remorph is absent / not in group roster
  local group_roster = mock_group_roster( { p( "Axtrox", "Warrior" ) } )
  local softres = mock_softres( 33150, {
    { name = "Axtrox", rolls = 1 },
    { name = "Remorph", rolls = 1 }
  } )

  local gui_data = mod.new( softres, group_roster )

  -- When / Then: start must not throw nil indexing error on absent player
  gui_data.start( 33150 )
  local result = gui_data.get()

  lu.assertEquals( #result, 2 )
  lu.assertEquals( result[ 1 ].player_name, "Axtrox" )
  lu.assertEquals( result[ 1 ].player_class, "Warrior" )
  lu.assertEquals( result[ 2 ].player_name, "Remorph" )
  lu.assertEquals( result[ 2 ].player_class, nil )
end

function SoftResRollGuiDataSpec:should_add_roll_and_sort_correctly()
  local group_roster = mock_group_roster( { p( "Kasia", "Priest" ), p( "Prixi", "Priest" ) } )
  local softres = mock_softres( 16921, {
    { name = "Kasia", rolls = 1 },
    { name = "Prixi", rolls = 1 }
  } )

  local gui_data = mod.new( softres, group_roster )
  gui_data.start( 16921 )

  gui_data.add_roll( "Kasia", 45 )
  gui_data.add_roll( "Prixi", 92 )

  local result = gui_data.get()
  lu.assertEquals( result[ 1 ].player_name, "Prixi" )
  lu.assertEquals( result[ 1 ].roll, 92 )
  lu.assertEquals( result[ 2 ].player_name, "Kasia" )
  lu.assertEquals( result[ 2 ].roll, 45 )
end

os.exit( lu.LuaUnit.run( "-o", "text", "-v", "-T", "Spec", "-m", "should" ) )
