package.path = "./?.lua;" .. package.path .. ";../?.lua;../RollFor/?.lua;../RollFor/libs/?.lua;../RollFor/libs/vanilla/LibStub/?.lua"

local u = require( "test/utils" )
local lu = u.luaunit()
local eq = lu.assertEquals

require( "src/bcc/compat" )
local m = u.modules()
u.mock_wow_api()
require( "src/Types" )
local mod = require( "src/SoftResDataTransformer" )

local datasets = require( "test/fixtures/pysanka_production_data" )

PysankaProductionFixturesSpec = {}

function PysankaProductionFixturesSpec:should_transform_bwl_fixture_3T9RB7()
  local data = datasets.bwl_3T9RB7
  local sr_result, hr_result = mod.transform( data )

  -- Check metadata
  eq( "3T9RB7", m.raid_id )

  -- Gankhorde: Item 19406 (Ashjre'thul) with +70 SR+
  local ashjre = sr_result[ 19406 ]
  local gankhorde = m.find( "Gankhorde", ashjre.rollers, "name" )
  eq( "Gankhorde", gankhorde.name )
  eq( 70, gankhorde.sr_plus )

  -- Criishacea: Item 19334 (Elementium Band) with +60 SR+
  local band = sr_result[ 19334 ]
  local criishacea = m.find( "Criishacea", band.rollers, "name" )
  eq( 60, criishacea.sr_plus )

  -- Dilitiria: Multi-reservation on Item 16905 (Bloodfang Boots) -> rolls = 2, sr_plus = 40
  local boots = sr_result[ 16905 ]
  local dilitiria = m.find( "Dilitiria", boots.rollers, "name" )
  eq( 2, dilitiria.rolls )
  eq( 40, dilitiria.sr_plus )

  -- Count total players in BWL
  local players = {}
  for _, entry in pairs( sr_result ) do
    for _, roller in ipairs( entry.rollers ) do
      players[ roller.name ] = true
    end
  end
  local total_players = 0
  for _ in pairs( players ) do total_players = total_players + 1 end
  eq( 40, total_players )
end

function PysankaProductionFixturesSpec:should_transform_onyxia_fixture_GU87B3_with_turtle_boss_drops()
  local data = datasets.onyxia_GU87B3
  local sr_result, hr_result = mod.transform( data )

  eq( "GU87B3", m.raid_id )

  -- Pysanka: Item 18813 (Ring of Binding) with +70 SR+
  local ring = sr_result[ 18813 ]
  local pysanka = m.find( "Pysanka", ring.rollers, "name" )
  eq( 70, pysanka.sr_plus )

  -- Turtle WoW Axelus Drop: Item 33153 (Axtrox, +40 SR+)
  local axelus_drop1 = sr_result[ 33153 ]
  local axtrox = m.find( "Axtrox", axelus_drop1.rollers, "name" )
  eq( "Axtrox", axtrox.name )
  eq( 40, axtrox.sr_plus )

  -- Turtle WoW Axelus Drop: Item 33150 (Remorph, +10 SR+)
  local axelus_drop2 = sr_result[ 33150 ]
  local remorph = m.find( "Remorph", axelus_drop2.rollers, "name" )
  eq( "Remorph", remorph.name )
  eq( 10, remorph.sr_plus )

  -- Turtle WoW Axelus Drop: Item 33156 (Turtlerecall, +30 SR+)
  local axelus_drop3 = sr_result[ 33156 ]
  local turtlerecall = m.find( "Turtlerecall", axelus_drop3.rollers, "name" )
  eq( "Turtlerecall", turtlerecall.name )
  eq( 30, turtlerecall.sr_plus )
end

function PysankaProductionFixturesSpec:should_transform_onyxia_fixture_XM8PH3_with_rare_backpack()
  local data = datasets.onyxia_XM8PH3
  local sr_result, hr_result = mod.transform( data )

  eq( "XM8PH3", m.raid_id )

  -- Onyxia Hide Backpack: Item 17966 (Rare Quality 3, BoE)
  local backpack = sr_result[ 17966 ]
  eq( 3, backpack.quality )
  -- 7 players reserved it
  eq( 7, m.getn( backpack.rollers ) )

  -- Broman has +30 SR+ on the backpack
  local broman = m.find( "Broman", backpack.rollers, "name" )
  eq( "Broman", broman.name )
  eq( 30, broman.sr_plus )
end

function PysankaProductionFixturesSpec:should_transform_emerald_sanctum_fixture_FZK7SP()
  local data = datasets.emerald_sanctum_FZK7SP
  local sr_result, hr_result = mod.transform( data )

  eq( "FZK7SP", m.raid_id )

  -- Pysanka: Item 61522 with +50 SR+
  local item_61522 = sr_result[ 61522 ]
  local pysanka = m.find( "Pysanka", item_61522.rollers, "name" )
  eq( "Pysanka", pysanka.name )
  eq( 50, pysanka.sr_plus )

  -- Item 61215: 7 rollers
  local staff = sr_result[ 61215 ]
  eq( 7, m.getn( staff.rollers ) )
  eq( true, m.find( "Joblesspally", staff.rollers, "name" ) ~= nil )
  eq( true, m.find( "Mayble", staff.rollers, "name" ) ~= nil )
  eq( true, m.find( "Bik", staff.rollers, "name" ) ~= nil )
  eq( true, m.find( "Axtrox", staff.rollers, "name" ) ~= nil )
end

os.exit( lu.LuaUnit.run( "-o", "text", "-v", "-T", "Spec", "-m", "should" ) )
