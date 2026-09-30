package.path = "./?.lua;./test/?.lua;" .. package.path .. ";../?.lua;../RollFor/?.lua;../RollFor/libs/?.lua;../RollFor/libs/vanilla/LibStub/?.lua"

local u = require( "test/utils" )
local lu, eq = u.luaunit( "assertEquals" )

require( "src/bcc/compat" )
local m = u.modules()
require( "src/BossList" )

BossListSpec = {}

function BossListSpec:should_contain_axelus_and_onyxia_in_onyxias_lair()
  local bosses = m.BossList.zones[ "Onyxia's Lair" ]
  eq( true, m.table_contains_value( bosses, "Onyxia" ) )
  eq( true, m.table_contains_value( bosses, "Broodcommander Axelus" ) )
end

function BossListSpec:should_contain_custom_turtle_mc_bosses()
  local bosses = m.BossList.zones[ "Molten Core" ]
  eq( true, m.table_contains_value( bosses, "Incindis" ) )
  eq( true, m.table_contains_value( bosses, "Basalthar" ) )
  eq( true, m.table_contains_value( bosses, "Smoldaris" ) )
  eq( true, m.table_contains_value( bosses, "Sorcerer-Thane Thaurissan" ) )
end

os.exit( lu.LuaUnit.run( "-o", "text", "-v", "-T", "Spec", "-m", "should" ) )
