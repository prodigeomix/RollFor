Confirmed against the actual source in your zip — the audit report's Issue 1 write-up matches the code exactly. Here's the breakdown:

## Why SR+ isn't being applied to rolls

**Confidence: 95%** (verified directly against your uploaded source)

The failure is a single dead code path, not a logic bug in the roll math:

| Location | What happens | Verified? |
|---|---|---|
| `src/SoftResDataTransformer.lua:82` | `roller.sr_plus = tonumber( item.sr_plus )` — only reads the flat field `sr_plus` | ✅ confirmed at exact line 82 |
| `src/SoftResRollingLogic.lua:207-208` | `if player.sr_plus then roll = roll + player.sr_plus end` | ✅ confirmed at exact lines 207-208, logic is correct |
| Type annotation `src/SoftResDataTransformer.lua:33` | `---@field sr_plus number` — the addon has only ever modeled SR+ as a flat number under the old `raidres.fly.dev` schema (`softreserves[].items[].sr_plus`) | ✅ confirmed |

So the roll-math side is fine — it just never receives a value, because `tonumber(item.sr_plus)` returns `nil` whenever `item.sr_plus` doesn't exist or isn't a plain string/number.

**The chain that breaks it:**
1. RollFor never talks to raidres over the network — WoW 1.12 addons can't make HTTP calls. Your raid leader copies an export string from the raidres website and pastes it into RollFor's import box (confirmed in `main.lua` / `SoftResGui.lua` / `SoftRes.lua:decode`).
2. If that pasted JSON comes from `raidres.top` (the newer site) instead of the old `raidres.fly.dev`, and the field is `srPlus` (camelCase, and per the audit report's API check, a nested `{value, isValid}` object) instead of a flat `sr_plus` number, `SoftResDataTransformer.lua:82` silently returns `nil`.
3. `nil` propagates to `SoftResRollingLogic.lua:208`, the `if player.sr_plus then` check never fires, and the roll goes out with no bonus — SR+ just doesn't count.

**Where my confidence drops:** I could independently verify everything on RollFor's side (95%+, it's your source). I could **not** independently verify raidres.top's current live JSON shape — I searched and got nothing usable on such a niche site, so the "camelCase / nested object" claim is resting entirely on the audit report's own stated API check (reservation `9HX42W`), which I haven't confirmed myself. Confidence on *that specific detail*: ~60%. It's plausible and consistent with a Next.js rewrite, but treat it as unverified until someone pastes you actual raidres.top export text to diff against.

One thing worth flagging since I'm not just taking the bundled reports at face value: **Issue 2 in the audit report (premature switch to Group Loot) does not match your current source.** The report describes an `m_item_count` counter that decrements on every `LOOT_SLOT_CLEARED` including coins. That variable doesn't exist anywhere in your zip's `AutoGroupLoot.lua` — the file there is a different, already-rewritten state machine (`m_looting_boss`/`m_boss_items`, threshold-based item registration, re-reading `loot_list.get_items()` live instead of decrementing a stale counter) that matches what the PDF briefing describes as already "Patched & Verified." So that report is either stale or describes a different branch — SR+ is your live bug, not the loot-switching one.

## Fix options

| Approach | Pros | Cons |
|---|---|---|
| **Patch `SoftResDataTransformer.lua`** to accept both `sr_plus` (old, flat) and `srPlus` (new, possibly `{value=...}` object) | Fixes it for every raid leader immediately, no dependency on external tools; small, isolated diff (~10 lines) | Doesn't fix the underlying data-shape mismatch — brittle if raidres.top's schema changes shape again; you're guessing at the exact new shape (60% confidence) until confirmed with a real paste |
| **Fix the export path instead** (working browser extension/userscript for raidres.top, or ask raidres.top for a "legacy RollFor export" button) | Fixes it at the source; no addon code risk | Outside your control — depends on a third-party extension author or the raidres.top maintainer (itamedruids) shipping something; slower, no ETA |
| **Do both** | Robust — RollFor no longer breaks silently on the *next* raidres schema change either | More work now for a bug that (from what's verified) only needs the transformer patch to be resolved |

Want me to write the actual patch to `SoftResDataTransformer.lua` handling both shapes? I'd want one real pasted raidres.top export string first to confirm the exact field shape rather than guess at it.