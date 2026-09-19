package.path = "./?.lua;./test/?.lua;" .. package.path .. ";../?.lua;../RollFor/?.lua;../RollFor/libs/?.lua;../RollFor/libs/vanilla/LibStub/?.lua"

local u = require( "test/utils" )
local lu = require( "luaunit" )
local eq = lu.assertEquals
local assertTrue = lu.assertTrue
local assertFalse = lu.assertFalse

require( "src/bcc/compat" )
local m = u.modules()
u.mock_wow_api()
require( "src/Types" )
require( "src/ItemUtils" )
require( "src/DebugBuffer" )
require( "src/Module" )
require( "src/SoftResDataTransformer" )
local equiv = require( "src/ItemEquivalence" )
local SoftRes = require( "src/SoftRes" )
local AwardedLoot = require( "src/AwardedLoot" )

ItemEquivalenceSpec = {}

function ItemEquivalenceSpec:should_return_equivalent_item_ids_for_paladin_t2_bracers()
  -- 16951: Judgement Bracers (Holy)
  -- 47019: Judgement Wristguards (Prot)
  -- 47027: Judgement Bindings (Ret)
  assertTrue( equiv.are_items_equivalent( 16951, 47019 ) )
  assertTrue( equiv.are_items_equivalent( 47019, 47027 ) )
  assertTrue( equiv.are_items_equivalent( 16951, 47027 ) )
  assertTrue( equiv.are_items_equivalent( 16951, 16951 ) )

  local ids = equiv.get_equivalent_item_ids( 47019 )
  eq( 3, m.getn( ids ) )
  eq( 16951, ids[ 1 ] )
  eq( 47019, ids[ 2 ] )
  eq( 47027, ids[ 3 ] )
end

function ItemEquivalenceSpec:should_return_equivalent_item_ids_for_priest_t2_gloves()
  -- 16920: Handguards of Transcendence (Holy)
  -- 47210: Handguards of Transcendence (Disc/Shadow)
  assertTrue( equiv.are_items_equivalent( 16920, 47210 ) )
  assertTrue( equiv.are_items_equivalent( 47210, 16920 ) )

  local ids = equiv.get_equivalent_item_ids( 47210 )
  eq( 2, m.getn( ids ) )
  eq( 16920, ids[ 1 ] )
  eq( 47210, ids[ 2 ] )
end

function ItemEquivalenceSpec:should_return_equivalent_item_ids_for_paladin_aq40_head()
  -- 21387: Avenger's Crown
  -- 47032: Avenger's Helmet
  -- 47037: Avenger's Helm
  assertTrue( equiv.are_items_equivalent( 21387, 47032 ) )
  assertTrue( equiv.are_items_equivalent( 47032, 47037 ) )

  local ids = equiv.get_equivalent_item_ids( 47032 )
  eq( 3, m.getn( ids ) )
  eq( 21387, ids[ 1 ] )
  eq( 47032, ids[ 2 ] )
  eq( 47037, ids[ 3 ] )
end

function ItemEquivalenceSpec:should_return_equivalent_item_ids_for_druid_t3_chest()
  -- 22488: Dreamwalker Tunic
  -- 47374: Dreamwalker Vest
  -- 47383: Dreamwalker Raiment
  assertTrue( equiv.are_items_equivalent( 22488, 47374 ) )
  assertTrue( equiv.are_items_equivalent( 47374, 47383 ) )

  local ids = equiv.get_equivalent_item_ids( 47383 )
  eq( 3, m.getn( ids ) )
  eq( 22488, ids[ 1 ] )
end

function ItemEquivalenceSpec:should_return_false_for_non_equivalent_items()
  assertFalse( equiv.are_items_equivalent( 16951, 16920 ) )
  assertFalse( equiv.are_items_equivalent( 16951, 999999 ) )
  assertFalse( equiv.are_items_equivalent( nil, 16951 ) )
  assertFalse( equiv.are_items_equivalent( 16951, nil ) )
end

function ItemEquivalenceSpec:should_return_singleton_for_unknown_item()
  local ids = equiv.get_equivalent_item_ids( 999999 )
  eq( 1, m.getn( ids ) )
  eq( 999999, ids[ 1 ] )
end

function ItemEquivalenceSpec:should_allow_registering_custom_group()
  equiv.register_group( { 888001, 888002, 888003 } )
  assertTrue( equiv.are_items_equivalent( 888001, 888003 ) )
  assertTrue( equiv.are_items_equivalent( 888002, 888003 ) )

  local ids = equiv.get_equivalent_item_ids( 888002 )
  eq( 3, m.getn( ids ) )
end

function ItemEquivalenceSpec:should_retrieve_softres_rollers_when_dropped_item_is_spec_variant()
  local db = {}
  local softres = SoftRes.new( db )

  -- Pysanka reserved 16951 (Judgement Bindings / Bracers)
  -- Banthracis reserved 16951 as well
  local data = {
    metadata = { id = "3T9RB7", origin = "raidres" },
    softreserves = {
      {
        name = "Pysanka",
        role = "PaladinProtection",
        items = { { id = 16951, quality = 4, sr_plus = 20 } }
      },
      {
        name = "Banthracis",
        role = "PaladinHoly",
        items = { { id = 16951, quality = 4, sr_plus = 10 } }
      }
    }
  }

  softres.import( data )

  -- Boss drops 47019 (Judgement Wristguards - Protection variant)
  local rollers = softres.get( 47019 )
  eq( 2, m.getn( rollers ) )

  -- Verify Pysanka is found with correct sr_plus
  local pysanka = rollers[ 1 ].name == "Pysanka" and rollers[ 1 ] or rollers[ 2 ]
  eq( "Pysanka", pysanka.name )
  eq( 1, pysanka.rolls )
  eq( 20, pysanka.sr_plus )

  -- Verify Banthracis is found with correct sr_plus
  local banthracis = rollers[ 1 ].name == "Banthracis" and rollers[ 1 ] or rollers[ 2 ]
  eq( "Banthracis", banthracis.name )
  eq( 1, banthracis.rolls )
  eq( 10, banthracis.sr_plus )

  -- Verify is_player_softressing
  assertTrue( softres.is_player_softressing( "Pysanka", 47019 ) )
  assertTrue( softres.is_player_softressing( "Banthracis", 47019 ) )
  assertFalse( softres.is_player_softressing( "SomeoneElse", 47019 ) )

  -- Verify get_item_quality returns 4
  eq( 4, softres.get_item_quality( 47019 ) )
end

function ItemEquivalenceSpec:should_merge_rollers_if_reserved_different_variants()
  local db = {}
  local softres = SoftRes.new( db )

  -- Suppose PlayerA reserved 16951 and PlayerB reserved 47019 directly
  local data = {
    metadata = { id = "test", origin = "raidres" },
    softreserves = {
      {
        name = "PlayerA",
        role = "PaladinHoly",
        items = { { id = 16951, quality = 4 } }
      },
      {
        name = "PlayerB",
        role = "PaladinProtection",
        items = { { id = 47019, quality = 4 } }
      }
    }
  }

  softres.import( data )

  -- Both should be returned whether checking 16951, 47019, or 47027
  local r_16951 = softres.get( 16951 )
  eq( 2, m.getn( r_16951 ) )

  local r_47019 = softres.get( 47019 )
  eq( 2, m.getn( r_47019 ) )

  local r_47027 = softres.get( 47027 )
  eq( 2, m.getn( r_47027 ) )
end

function ItemEquivalenceSpec:should_recognize_awarded_loot_across_equivalent_items()
  local db = {}
  local group_roster = { find_player = function() return nil end }
  local config = { keep_award_data = function() return true end }
  local awarded_loot = AwardedLoot.new( db, group_roster, config )

  -- Award 47019 (Judgement Wristguards) to Pysanka
  awarded_loot.award( "Pysanka", 47019, nil, nil, "[Judgement Wristguards]", "PALADIN", 20, false )

  -- has_item_been_awarded should return true for 47019 AND 16951 AND 47027
  assertTrue( awarded_loot.has_item_been_awarded( "Pysanka", 47019 ) )
  assertTrue( awarded_loot.has_item_been_awarded( "Pysanka", 16951 ) )
  assertTrue( awarded_loot.has_item_been_awarded( "Pysanka", 47027 ) )

  -- But false for unrelated item (e.g. 16920 Handguards of Transcendence)
  assertFalse( awarded_loot.has_item_been_awarded( "Pysanka", 16920 ) )

  -- how_many_awarded
  eq( 1, awarded_loot.how_many_awarded( "Pysanka", 16951 ) )
  eq( 1, awarded_loot.how_many_awarded( "Pysanka", 47019 ) )
  eq( 0, awarded_loot.how_many_awarded( "Pysanka", 16920 ) )

  -- has_item_been_awarded_to_any_player
  assertTrue( awarded_loot.has_item_been_awarded_to_any_player( 16951 ) )
  assertTrue( awarded_loot.has_item_been_awarded_to_any_player( 47019 ) )
  assertFalse( awarded_loot.has_item_been_awarded_to_any_player( 16920 ) )
end

os.exit( lu.LuaUnit.run( "-o", "text", "-v", "-T", "Spec", "-m", "should" ) )
