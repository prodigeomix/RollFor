package.path = "./?.lua;" .. package.path .. ";../?.lua;../RollFor/?.lua;../RollFor/libs/?.lua;../RollFor/libs/vanilla/LibStub/?.lua"

local u = require( "test/utils" )
local lu, eq = u.luaunit( "assertEquals" )

-- Load Bcc compat (sets M.mod, M.getn — Lua 5.1 shims) BEFORE modules
require( "src/bcc/compat" )
local m = u.modules()
u.mock_wow_api()
require( "src/Types" )
local mod = require( "src/SoftResDataTransformer" )

SRPlusFormatSpec = {}

function SRPlusFormatSpec:should_extract_sr_plus_from_raidres_top_object()
  -- raidres.top export format: srPlus as {value=NUM, isValid=BOOL} object
  local data = {
    metadata = { id = "test", origin = "raidres" },
    reservations = {
      {
        character = { name = "Carbon", class = "Priest" },
        raidItemId = 6724,
        srPlus = { value = 10, isValid = true }
      }
    }
  }
  local sr_result, hr_result = mod.transform( data )
  eq( 10, sr_result[ 6724 ].rollers[ 1 ].sr_plus )
  eq( "Carbon", sr_result[ 6724 ].rollers[ 1 ].name )
end

function SRPlusFormatSpec:should_not_extract_invalid_sr_plus()
  local data = {
    metadata = { id = "test", origin = "raidres" },
    reservations = {
      {
        character = { name = "Carbon", class = "Priest" },
        raidItemId = 6724,
        srPlus = { value = 50, isValid = false }
      }
    }
  }
  local sr_result, hr_result = mod.transform( data )
  eq( nil, sr_result[ 6724 ].rollers[ 1 ].sr_plus )
end

function SRPlusFormatSpec:should_handle_legacy_string_sr_plus()
  local data = {
    metadata = { id = "legacy", origin = "raidres" },
    softreserves = {
      { name = "Carbon", role = "PriestHoly", items = { { id = 17204, quality = 4, sr_plus = "5" } } }
    }
  }
  local sr_result, hr_result = mod.transform( data )
  eq( 5, sr_result[ 17204 ].rollers[ 1 ].sr_plus )
end

function SRPlusFormatSpec:should_handle_legacy_number_sr_plus()
  local data = {
    metadata = { id = "legacy", origin = "raidres" },
    softreserves = {
      { name = "Carbon", role = "PriestHoly", items = { { id = 17204, quality = 4, sr_plus = 40 } } }
    }
  }
  local sr_result, hr_result = mod.transform( data )
  eq( 40, sr_result[ 17204 ].rollers[ 1 ].sr_plus )
end

function SRPlusFormatSpec:should_handle_new_format_reservation_without_sr_plus()
  local data = {
    metadata = { id = "test", origin = "raidres" },
    reservations = {
      {
        character = { name = "Carbon", class = "Priest" },
        raidItemId = 8129
        -- No srPlus field — player didn't set SR+
      }
    }
  }
  local sr_result, hr_result = mod.transform( data )
  eq( nil, sr_result[ 8129 ].rollers[ 1 ].sr_plus )
end

os.exit( lu.LuaUnit.run( "-o", "text", "-v", "-T", "Spec", "-m", "should" ) )
