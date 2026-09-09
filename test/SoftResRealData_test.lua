package.path = "./?.lua;" .. package.path .. ";../?.lua;../RollFor/?.lua;../RollFor/libs/?.lua;../RollFor/libs/vanilla/LibStub/?.lua"

local u = require( "test/utils" )
local lu, eq = u.luaunit( "assertEquals" )

require( "src/bcc/compat" )
local m = u.modules()
u.mock_wow_api()
require( "src/Types" )
local mod = require( "src/SoftResDataTransformer" )

-- Real raidres.top data from example soft reserves.txt (reservation 85KQ8S)
local real_data = require( "fixtures/real_raidres_data" )

SoftResDataTransformerRealDataSpec = {}

function SoftResDataTransformerRealDataSpec:should_parse_real_raidres_data_carbon_sr_plus()
  local sr_result, hr_result = mod.transform( real_data )
  eq( "Carbon", sr_result[ 18646 ].rollers[ 1 ].name )
  eq( 60, sr_result[ 18646 ].rollers[ 1 ].sr_plus )
end

function SoftResDataTransformerRealDataSpec:should_parse_all_40_players()
  local sr_result, hr_result = mod.transform( real_data )
  local players = {}
  for _, entry in pairs( sr_result ) do
    for _, roller in ipairs( entry.rollers ) do
      players[ roller.name ] = true
    end
  end
  local count = 0
  for _ in pairs( players ) do count = count + 1 end
  eq( 40, count )
end

function SoftResDataTransformerRealDataSpec:should_parse_4_hard_reserves()
  local sr_result, hr_result = mod.transform( real_data )
  eq( 5, hr_result[ 17782 ].quality )
  eq( 5, hr_result[ 17204 ].quality )
  eq( 5, hr_result[ 18564 ].quality )
  eq( 5, hr_result[ 18563 ].quality )
end

function SoftResDataTransformerRealDataSpec:should_handle_items_without_sr_plus()
  local sr_result, hr_result = mod.transform( real_data )
  local found_nil_sr_plus = false
  for _, entry in pairs( sr_result ) do
    for _, roller in ipairs( entry.rollers ) do
      if roller.sr_plus == nil then
        found_nil_sr_plus = true
        break
      end
    end
  end
  eq( true, found_nil_sr_plus )
end

os.exit( lu.LuaUnit.run( "-o", "text", "-v", "-T", "Spec", "-m", "should" ) )
