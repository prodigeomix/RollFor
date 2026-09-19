# RollFor Audit: SR+ and AutoGroupLoot Bugs

## Issue 1: SR+ Not Calculated from Raidres Sheet

### Root Cause: Raidres Format Change

The raidres website moved from `raidres.fly.dev` (old) to `raidres.top` (new rewrite by itamedruids). The data format changed in a way that breaks SR+ extraction.

**Old raidres.fly.dev format (what RollFor expects):**
```json
{
  "softreserves": [
    {
      "name": "Carbon",
      "items": [
        {"id": 6724, "sr_plus": "10"}
      ]
    }
  ]
}
```

**New raidres.top format (verified via API on reservation 9HX42W):**
```json
{
  "reservations": [
    {
      "character": {"name": "Carbon", "class": "Priest"},
      "raidItemId": 6724,
      "srPlus": {"value": 10, "isValid": false}
    }
  ],
  "allowSrPlus": true,
  "defaultSrPlusIncrease": 10
}
```

### Why SR+ Breaks

1. **Field name mismatch**: Old code expects `sr_plus` (snake_case), new API uses `srPlus` (camelCase)
2. **Type mismatch**: Old code expects `item.sr_plus` to be a string/number. New API provides `srPlus` as an **object** `{"value": 10, "isValid": false}`
3. **Chrome extension broken**: `BahamutxD/RaidRes-extractor` targets old raidres.fly.dev DOM selectors (`tbody.m_b2404537`, `td.m_4e7aa4fd`). New raidres.top is a Next.js app with different class names
4. **Extension extracts from comments**: The old extension parses `SR+5` pattern from player note fields. New raidres.top stores SR+ as structured data, not in comments

### RollFor Code Path (CORRECT, but data never arrives)

- `SoftResDataTransformer.lua:82` — `roller.sr_plus = tonumber(item.sr_plus)`
  - `tonumber(table)` returns `nil` in Lua, so even if the field name matched, an object would fail
- `SoftResRollingLogic.lua:207-208` — `if player.sr_plus then roll = roll + player.sr_plus end`
  - This code is correct; it never fires because `sr_plus` is `nil`

### Fix

Update `SoftResDataTransformer.lua` to handle both formats:

```lua
-- Line 82: support both old (string/number) and new (object with .value) formats
local sr_plus_value
if type(item.sr_plus) == "string" or type(item.sr_plus) == "number" then
    sr_plus_value = tonumber(item.sr_plus)
elseif type(item.sr_plus) == "table" and item.sr_plus.value then
    sr_plus_value = tonumber(item.sr_plus.value)
elseif type(item.srPlus) == "table" and item.srPlus.value then
    sr_plus_value = tonumber(item.srPlus.value)
elseif type(item.srPlus) == "string" or type(item.srPlus) == "number" then
    sr_plus_value = tonumber(item.srPlus)
end
roller.sr_plus = sr_plus_value
```

Also update the field path: if the new API nests reservations under `data.reservations` with `character.name` instead of `data.softreserves` with `name`, the entire transform function needs updating to handle both structures.

Additionally, the `BahamutxD/RaidRes-extractor` Chrome extension needs its CSS selectors updated for the new raidres.top DOM, OR raidres.top should restore a built-in "RollFor export" button that generates the correct format.

---

## Issue 2: Addon Switches to Group Loot Prematurely

### Root Cause: `AutoGroupLoot.lua` counts non-item slot clears

In `src/AutoGroupLoot.lua`, `on_loot_slot_cleared()` decrements `m_item_count` for **every** `LOOT_SLOT_CLEARED` event:

```lua
local function on_loot_slot_cleared()
    if m_item_count == nil then return end
    m_item_count = m_item_count - 1
    if m_item_count > 0 then return end
    -- Switch to group loot
end
```

But `LOOT_SLOT_CLEARED` fires for **all** loot slot types, including gold/coin slots. The `m_item_count` is initialized from only item slots (via `loot_list.get_items()`), so clearing a coin slot decrements the counter without a corresponding item, causing premature switch to group loot.

### Example scenario
1. Loot window has 2 items + 1 gold coin (3 slots)
2. `m_item_count` = 2 (only items counted)
3. Player clicks gold coin → `LOOT_SLOT_CLEARED` fires → `m_item_count` = 1
4. Player assigns item 1 → `LOOT_SLOT_CLEARED` fires → `m_item_count` = 0 → **switch to group loot!**
5. Item 2 is still in loot window but master loot mode is gone

### Fix

In `on_loot_slot_cleared`, check slot type before decrementing:

```lua
local function on_loot_slot_cleared( slot_index )
    if m_item_count == nil then return end
    -- In WoW 1.12/Turtle, GetLootSlotLink returns nil for money slots
    local slot_link = GetLootSlotLink( slot_index )
    if not slot_link then
        return  -- Money/coin slot, don't decrement item counter
    end
    m_item_count = m_item_count - 1
    if m_item_count > 0 then return end
    -- ... rest of the function unchanged
end
```

Alternatively, register for `LootSlotHasLink`-based filtering in the event handler registration.

---

## Issue 3: raidres.top JSON Structure Changed (Not Just SR+ Fields)

### Root Cause: Field name and structure changes in raidres.top export

The audit report's Issue 1 fix (extract_sr_plus) only addressed the **SR+ value field** (`sr_plus` → `srPlus` object), but missed a deeper structural change. The raidres.top export (post-November 2025 migration) completely changed the JSON schema:

**Old raidres.fly.dev structure (expected by transform()):**
```json
{
  "softreserves": [
    { "name": "Carbon", "role": "DD", "items": [{ "id": 6724, "quality": 4, "sr_plus": "10" }] }
  ],
  "hardreserves": []
}
```

**New raidres.top structure (NOT handled by original transform()):**
```json
{
  "reservations": [
    {
      "character": { "name": "Carbon", "class": "Priest" },
      "raidItemId": 6724,
      "srPlus": { "value": 10, "isValid": true }
    }
  ],
  "hardreserves": [],
  "allowSrPlus": true,
  "defaultSrPlusIncrease": 10
}
```

### Key structural differences:
1. **Top-level field**: `softreserves` → `reservations`
2. **Player name**: `sr.name` → `sr.character.name` (nested object)
3. **Item ID**: `item.id` (nested in array) → `entry.raidItemId` (flat, one entry per reservation)
4. **SR+ field**: `item.sr_plus` (on nested item) → `entry.srPlus` (on the reservation entry itself)

### RollFor Code Path

- `SoftResDataTransformer.lua:83-84` — `transform()` reads `data.softreserves` and `data.hardreserves` only. The `data.reservations` array is completely ignored.
- `SoftRes.lua:45-66` — `decode()` base64-decodes then JSON-parses, passing the result directly to `transform()`. No structural translation occurs.
- Result: When a user imports data from raidres.top (the current production site), `soft_reserves` is `nil`, so `transform()` returns empty tables. The soft-res list shows nothing — the addon appears completely broken for SR imports.

### Fix Applied

Added a new `new_reservations` parser loop in `transform()` that handles the new format alongside the legacy parser. The `extract_sr_plus()` function (from Issue 1 fix) is reused to handle both `srPlus` on the entry level and `sr_plus` on the legacy nested item level.

```lua
-- Handle new raidres.top format: reservations with character.name and raidItemId
for _, entry in ipairs( new_reservations ) do
  local character = entry.character or {}
  local roller_name = character.name
  local item_id = entry.raidItemId or entry.id

  if item_id and roller_name then
    -- ... same roller/quality logic, calling extract_sr_plus(entry)
  end
end
```

### Verification Against Real Data

The addon's `example soft reserves.txt` file (reservation ID: 85KQ8S) was decoded and tested:

**Format of real exported data (reservation 85KQ8S):**
```json
{
  "metadata": { "id": "85KQ8S", "instance": 95, "origin": "raidres" },
  "softreserves": [
    { "name": "Carbon", "role": "PriestHoly",
      "items": [{ "id": 18646, "quality": 4, "sr_plus": 60 }, ...] }
  ],
  "hardreserves": [...]
}
```

Key finding: the **real-world export still uses the legacy structure** (`softreserves`, `sr.items[].sr_plus` as bare integers), NOT the new `reservations`/`srPlus` format. The original upstream code (`tonumber(item.sr_plus)`) handles this correctly — `tonumber(60)` returns `60` in Lua 5.1.

The `reservations`/`srPlus` object format appears in the raidres.top SR+ validation UI (documented at `https://raidres.top/sr-plus-standard`), which may produce a different export when SR+ validation is enabled. The `extract_sr_plus` fix and the `reservations` parser are **defensive measures** for that context — verified via targeted LuaUnit tests, not real raid data.

**Test results (ALL PASS):**
- Original upstream code against real data (4 tests): PASS — bare integer `sr_plus` works with `tonumber()`
- Fixed code against real data (4 tests): PASS — no regression
- Fixed code against SR+ object format (5 tests): PASS — handles `{value=N, isValid=BOOL}` correctly
- Fixed code against legacy format (4 tests): PASS — backward compatible

### SR+ Standard Documentation

Per the raidres.top SR+ standard (v3.2, pasted from `https://raidres.top/sr-plus-standard`):
- Points range from 0 to 100,000 (increased from 1,000 in v1)
- SR+ validity flag: "If at least one reservation is marked as valid, only valid entries will be exported to CSV, RollFor, and similar addons"
- The `isValid == false` guard in `extract_sr_plus()` correctly handles the "unchecked/zero-value" case

---

## Files Examined

- `src/SoftRes.lua` — SR data management, decoding, and import flow
- `src/SoftResDataTransformer.lua` — JSON to internal format: `extract_sr_plus()` for SR+ field parsing, `transform()` for structural parsing (both formats)
- `src/SoftResRollingLogic.lua` — SR+ application in rolls (lines 207-208)
- `src/AutoGroupLoot.lua` — Group loot auto-switching with coin-slot filtering
- `src/AutoMasterLoot.lua` — Master loot auto-switching
- `src/LootController.lua` — Loot window event handling
- `src/RollController.lua` — Roll tracking
- `src/Types.lua` — Player/Roller data structures
- `src/main.lua` — Entry point, data import
- `src/SoftResCheck.lua` — SR status display
- `src/LootAwardCallback.lua` — Award tracking with SR+
- `README.md` — Documents raidres integration

---

## Issue 4: Sub-Threshold Reserved Loot Dropping Without Announcement (v4.8.4)

### Problem
In raids using an Epic (quality 4) master loot threshold, rare (quality 3) or uncommon (quality 2) reserved items (such as the 18-slot Onyxia Hide Backpack #17966) were ignored by `DroppedLootAnnounce.lua`, resulting in no raid warning and no queue entry in the loot frame.

### Fix
Updated `src/DroppedLootAnnounce.lua` so that any item flagged as soft-reserved (`softres.is_player_softressing`) or hard-reserved (`softres.is_item_hardressed`) bypasses the `quality >= loot_threshold` check.

---

## Issue 5: Duplicate Reservation SR+ Value Discard (v4.8.4)

### Problem
When a player had multiple reservations on the same item, or when reservations were merged, subsequent `srPlus` values were discarded in `SoftResDataTransformer.lua`.

### Fix
Updated `src/SoftResDataTransformer.lua` to retain and apply `math.max(existing_sr_plus, new_sr_plus)` across all merged reservations.

---

## Issue 6: Client Chat Message Splitting >255 Characters (v4.8.4)

### Problem
The WoW 1.12 client silently drops or truncates chat messages longer than 255 characters. In raids with many rollers reserving the same popular item, the resulting raid warning was truncated.

### Fix
Implemented message boundary splitting in `src/Chat.lua` to break long messages at space or punctuation boundaries into sequential messages, preventing chat drops.

---

## Issue 7: Turtle WoW Raid Boss Drop Verification & Equivalence Reversion (v4.8.5)

### Findings
Following review and feedback from raid leader Pysanka (verified against real Blackwing Lair sheet `3T9RB7`), Turtle WoW raid bosses drop standard Vanilla item IDs directly (e.g. Razorgore drops Judgement Bindings `#16951`). Spec-variant sets are vendor exchange rewards outside the raid. The experimental `ItemEquivalence.lua` mapping layer was removed to prevent cross-contamination of soft-reserve groupings. Clean 1:1 ID matching was restored in `SoftRes.lua` and `AwardedLoot.lua`.

---

## Issue 8: SR+ Zeroed Out When Validation Disabled on raidres.top (v4.8.5)

### Problem
On `raidres.top`, when `requireSrPlusValidation` is `false` (default on most sheets, including `3T9RB7`), the API exports reservations with `srPlus: { value: N, isValid: false }`. The previous defensive guard `if item.srPlus.isValid == false then return nil end` mistakenly treated unvalidated entries as invalid, zeroing out SR+ bonuses for all players in the raid.

### Fix
Updated `extract_sr_plus()` in `src/SoftResDataTransformer.lua` to always extract the numeric `value` without checking `isValid`, ensuring legitimate SR+ points are preserved regardless of sheet validation settings.

---

## Lua 5.0 Compatibility Verification

All source files were scanned with the `validate_lua50.py` compatibility validator (ported from DiscPriest's standard audit toolkit) which detects post-Lua 5.0 syntax and API usage violations.

**Files modified by recent audits — all clean:**
- `src/SoftRes.lua` — 0 violations
- `src/AwardedLoot.lua` — 0 violations
- `src/SoftResDataTransformer.lua` — 0 violations
- `src/DroppedLootAnnounce.lua` — 0 violations
- `src/vanilla/compat.lua` — 0 violations

**Pre-existing violations (not in scope of this fix):**
- `src/bcc/compat.lua` — 3 violations (`#t`, `a % b`, `C_ChatInfo`) — BCC-only layer, not loaded in Vanilla/Turtle
- `src/vanilla/backport.lua` — 2 violations that are self-referential (defines `string.match`/`string.gmatch` for Lua 5.0 — these are the compatibility shims, not bugs)
- Various library files: `src/vanilla/Json.lua` — 3 violations

**Test execution environment note:** Tests were run under Lua 5.1 (the interpreter available on this system). Turtle WoW 1.18.1 uses Lua 5.0, where the `#` and `%` operators and `string.match`/`string.gmatch` do not exist. The `vanilla/backport.lua` compatibility shim provides these functions. All modified code uses only Lua 5.0-compatible constructs: `type()`, `tonumber()`, `pairs()`, `ipairs()`, `string.find` (with captures), and table indexing.
