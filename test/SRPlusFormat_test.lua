package.path = "./?.lua;./test/?.lua;" .. package.path .. ";../?.lua;../RollFor/?.lua;../RollFor/libs/?.lua;../RollFor/libs/vanilla/LibStub/?.lua"

local u = require( "test/utils" )
local lu = require( "luaunit" )
local eq = lu.assertEquals

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

function SRPlusFormatSpec:should_extract_sr_plus_when_isValid_is_false()
  -- On raidres.top, when requireSrPlusValidation is false, all entries have isValid = false.
  -- The numeric value must still be extracted.
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
  eq( 50, sr_result[ 6724 ].rollers[ 1 ].sr_plus )
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

function SRPlusFormatSpec:should_preserve_sr_plus_when_second_reservation_has_sr_plus()
  local data = {
    metadata = { id = "legacy", origin = "raidres" },
    softreserves = {
      {
        name = "PlayerA",
        role = "Hunter",
        items = {
          { id = 100, quality = 4 },
          { id = 100, quality = 4, sr_plus = 20 }
        }
      }
    }
  }
  local sr_result, hr_result = mod.transform( data )
  eq( 20, sr_result[ 100 ].rollers[ 1 ].sr_plus )
  eq( 2, sr_result[ 100 ].rollers[ 1 ].rolls )
end

function SRPlusFormatSpec:should_preserve_sr_plus_in_new_format_when_second_reservation_has_sr_plus()
  local data = {
    metadata = { id = "test", origin = "raidres" },
    reservations = {
      {
        character = { name = "PlayerB", class = "Warrior" },
        raidItemId = 200
      },
      {
        character = { name = "PlayerB", class = "Warrior" },
        raidItemId = 200,
        srPlus = { value = 30, isValid = true }
      }
    }
  }
  local sr_result, hr_result = mod.transform( data )
  eq( 30, sr_result[ 200 ].rollers[ 1 ].sr_plus )
  eq( 2, sr_result[ 200 ].rollers[ 1 ].rolls )
end

function SRPlusFormatSpec:should_pick_max_sr_plus_when_both_reservations_have_values()
  local data = {
    metadata = { id = "legacy", origin = "raidres" },
    softreserves = {
      {
        name = "PlayerC",
        role = "Mage",
        items = {
          { id = 300, quality = 4, sr_plus = 10 },
          { id = 300, quality = 4, sr_plus = 50 }
        }
      }
    }
  }
  local sr_result, hr_result = mod.transform( data )
  eq( 50, sr_result[ 300 ].rollers[ 1 ].sr_plus )
  eq( 2, sr_result[ 300 ].rollers[ 1 ].rolls )
end

os.exit( lu.LuaUnit.run( "-o", "text", "-v", "-T", "Spec", "-m", "should" ) )
