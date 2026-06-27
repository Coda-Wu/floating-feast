# STATE.md — *Floating Feast* Live Progress Ledger

**Read this first, every session.** It describes where we are **right now**. It is *overwritten* after every milestone to reflect the new present (history goes to JOURNAL.md, append-only). If this disagrees with the code, the code wins — flag the drift.

_Last updated: 2026-06-27 — workspace seeded from the prior web-chat session._

---

## Current focus

- **Milestone:** M1 demo (Cat Island, Mediterranean).
- **Active system:** **Universal Pause Menu / Backpack UI** (Stardew-style all-in-one `Esc` menu).
- **Next step:** **Step 3 — Backpack tab static layout.**

---

## Active build order — Universal Pause Menu

Each item is its own teach-then-code step behind a Verify gate.

- [x] **1. Menu shell + Esc gating + tab switching.** `PauseMenu` CanvasLayer (`PROCESS_MODE_ALWAYS`); `UIManager` modal registry (`register_modal`/`unregister_modal`/`is_modal_open`) + `_unhandled_input` Esc routing + pause-on-open; Fridge & Recipe Book register as modals. Six placeholder tab panels switch.
- [x] **2. Slot-ordered tagged-token inventory migration.** `GameState.inventory` is now a 30-slot `Array` of `{kind,id,count}`/null (hotbar = slots 0–9). ID API (`add_item`/`remove_item`/`get_item_count`) reimplemented over the array (callers untouched); added `get_slot`/`slot_count`/`get_carried_item_ids`; new `inventory_slots_changed` signal; serialize/deserialize round-trips + migrates legacy dict saves. `QuickAccessBar` rewritten to render row 0 by index (pagination removed). `spirit_encounter_node` feed-list repointed to `get_carried_item_ids()`.
- [ ] **3. Backpack tab static layout** ← NEXT. Upper-half 10-col grid (row 0 = hotbar slots, rows 1+ = backpack rows, all `ItemSlot`s reading the slot array by index) + lower-half profile (gray-box portrait + Name/Ship/Coins/Rank). **Add `GameState.player_name` + `ship_name` placeholder fields** (real fields, never hardcoded). Resolve the shared-tooltip layering (menu sits above the PersistentUI tooltip — menu-local tooltip or bump the tooltip layer).
- [ ] **4. Selection + number keys + red-outline highlight.**
- [ ] **5. Auto-Sort (by type) + Trash target (drag-drop delete, with confirm).**
- [ ] **6. Intra-grid drag-and-drop (full-stack swap/merge).**
- [ ] **7. External contextual drag (receiver-gated single item).** Retrofit the cook-station slot first as the reference receiver, then garden pot / spirit feed / fountain.
- [ ] **8. Spirits tab (grid + sort) + spirit-to-garden** via the drag rails (`kind: spirit`).
- [ ] **9. Quests tab (active list → detail/rewards).**
- [ ] **10. Stubs wired: NPCs, Settings, Leave Game (Return to Title / Quit).**

**Step-3 deferred-but-flagged carryovers:** capacity-full UX (Step 5 Trash/notify; 30 slots won't fill in M1); cooking refund position-shift (last-of-stack then cancel re-places in first empty slot); items beyond slot 9 aren't hotbar-cookable until drag (Step 6).

---

## Completed systems (done & verified)

- **Week 1 — daytime exploration (gray-box):** day-phase machine, ship hub, Kitchen (top-down), TopDownActor, Interactable/InteractionDetector. *(The original procedural exploration was later fully replaced — see below.)*
- **Week 2 / M1 — cook→deliver loop:** cooking sim (StationRecipe + intermediates + Dubious on mismatch), Recipe Book codex, Garden (assign spirit→pot→overnight yield; remove = permanent consume), Commissions + NPC delivery + CommissionHUD (soft-deadline additive bonus), Fair (tier-judged coins → rank).
- **Inventory-UX:** persistent 10-slot Quick Access hotbar (primary cooking surface); reusable `ItemSlot` + cursor tooltip; station cook-slots deduct-on-slot / refund-on-exit (`_exit_tree` catch); Fridge as paged grid + `fridge_storage`; number-key hotbar selection gated on station-open.
- **Cooking spice-constraint redesign (LOCKED):** tier = `clamp(2 + distinct compatible spices, 1, tier_cap)`; flavor-tag compatibility; set-aside (never wasted/Dubious); pipeline = only 5★ path. See DESIGN.md §3.
- **Open-book Fridge + Recipe Book:** shared hardened `BookFrame` (512×288), category bookmarks, info pages, visual recipe rows; driven by `CookingInfo`.
- **Exploration System Rework (all 9 steps COMPLETE):** Fuel+Time resources (fuel 6, node-driven time, 2 AM curfew, fuel-only gate); static fog-of-war Ocean Map of `WorldIslandData`; branching layered DAG via `RunGraphGenerator`/`RunGraph` held by `GameManager.run_graph`; previewable one-way path-map `IslandScreen` (fuel-on-entry, branch forfeit, loot-kept auto-return, capped 2 AM faint, manual retreat, overnight refuel/reset); DockNode; RewardNode + 3-mechanism Tier-S depletion (recipes/spirits/`island_depletion`) + 2× depleted terminal; SynergyEventNode (fungible-only buff, never Tier-S); **budget system deleted** + orphaned procedural classes removed; all-exits-to-ship + one-foray-per-day. See DESIGN.md §4, ARCHITECTURE.md §7–8.

---

## Deferred threads (parked, not forgotten)

- **Full Backpack book** (Quest/Map/NPC links) as a *third* `BookFrame` consumer — distinct from the full-screen Pause Menu; revisit after the Pause Menu.
- **Week 3:** pure art/audio asset swap (the architecture's whole purpose).
- **`IslandTemplate` + `_gen_islands`** broader cleanup (unused-but-harmless, still Database-indexed).
- **Spice Isle unlock** (currently phase 99 / fogged "to be continued").
- **Sweet dish** to un-orphan the sugar spice.
- **Fair cadence** (soft "every N days" per redesign) — logged follow-up.
- **Mining / fishing** — deferred; open decision whether they become node minigames or free on-ship daytime activities. If free on-ship: rewards stay consumable-tier; food never refuels Ember (the firewall).
- **M2:** name-entry onboarding (writes `player_name`/`ship_name`), Dialogic narrative slice, walkable ship deck, side-scroller Garden, additional World Islands, non-spirit slot kinds (ore/geode/furniture), Captain's-room steering wheel for the Ocean Map.
- **Steam roadmap:** Next Fest slot held for the launch run-up (not used early).

---

## How to update this file (reminder for the AI)

After each completed + verified step: rewrite the **Current focus** + the build-order checkbox + move the finished item into **Completed systems** if it closes a system, and **append a dated entry to JOURNAL.md**. Hand Coda the updated content as a snippet (you are read-only) and remind them to commit.
