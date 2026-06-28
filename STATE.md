# STATE.md — *Floating Feast* Live Progress Ledger

**Read this first, every session.** It describes where we are **right now**. It is *overwritten* after every milestone to reflect the new present (history goes to JOURNAL.md, append-only). If this disagrees with the code, the code wins — flag the drift.

_Last updated: 2026-06-28 — Spirit Garden G6 (shovel removal) complete; all garden mechanics done._






---

## Current focus

- **Milestone:** M1 demo (Cat Island, Mediterranean).
- **Active system:** **Spirit Garden epic** — walkable garden + spirits-as-entities + tools (canon: GARDEN.md). *(Pause Menu paused after Step 6; Step 7 deferred to M2; Steps 9–10 pending.)*
- **Next step:** **G1 — spirit-as-entity migration.**




---

## Active build order — Universal Pause Menu

Each item is its own teach-then-code step behind a Verify gate.

- [x] **1. Menu shell + Esc gating + tab switching.** `PauseMenu` CanvasLayer (`PROCESS_MODE_ALWAYS`); `UIManager` modal registry (`register_modal`/`unregister_modal`/`is_modal_open`) + `_unhandled_input` Esc routing + pause-on-open; Fridge & Recipe Book register as modals. Six placeholder tab panels switch.
- [x] **2. Slot-ordered tagged-token inventory migration.** `GameState.inventory` is now a 30-slot `Array` of `{kind,id,count}`/null (hotbar = slots 0–9). ID API (`add_item`/`remove_item`/`get_item_count`) reimplemented over the array (callers untouched); added `get_slot`/`slot_count`/`get_carried_item_ids`; new `inventory_slots_changed` signal; serialize/deserialize round-trips + migrates legacy dict saves. `QuickAccessBar` rewritten to render row 0 by index (pagination removed). `spirit_encounter_node` feed-list repointed to `get_carried_item_ids()`.
- [x] **3. Backpack tab static layout.** New `BackpackPanel` scene/script: upper-half 10-col grid of 30 `ItemSlot`s bound to `GameState` slots by index (row 0 = hotbar w/ hotkeys 1–0; refreshes on `inventory_slots_changed`) + lower-half profile (gray-box `ColorRect` portrait + Name/Ship/Coins/Rank from real fields). Added `GameState.player_name`/`ship_name` as real serialized fields (defaults Saff / "Saff's Ship"; M2 onboarding overwrites). Localized profile strings + all six tab labels in `zh.po`. **Menu-modal fix:** `UIManager` hides HUD+hotbar on open / restores phase-aware on close; `ItemTooltip` set `PROCESS_MODE_ALWAYS`. *(Drift corrected: `PersistentUI` layer 128 already sits above `PauseMenu` layer 5 — the tooltip was never behind the menu; the real issue was the HUD/hotbar floating over it.)*

- [x] **4. Selection + number keys + red-outline highlight.** `ItemSlot.set_selected(bool)` red-outline visual (stylebox border recolor; reusable). `BackpackPanel` owns a single `_selected_index`: click or number key `1–0` (row-0 slots, reusing `hotbar_*` actions, filled-only) outlines one slot at a time; re-selecting clears it. Menu-local (clears on close via panel rebuild); live hotbar/cooking untouched. Highlight-only groundwork — no action wired yet.
- [x] **5. Auto-Sort (by type) + Trash (select → confirm delete).** Right-aligned `Sort`/`Trash` toolbar in `BackpackPanel` (localized). `GameState.sort_inventory()` merges same-`(kind,id)` stacks, orders by type (`IngredientData.tags[0]` → display name; items before spirits), and compacts all 30 slots (hotbar included). Trash reuses Step-4 selection: `Trash` enables only when a slot is selected → always-processing `WarningPopup` confirm → `GameState.clear_slot(i)` empties that stack. Also fixed the 4b bug (all slots now click-selectable, not just row 0).
- [x] **6. Intra-grid drag-and-drop (full-stack swap/merge).** Godot built-in drag on `ItemSlot` (opt-in `drag_enabled`, carries `_slot_index`, `slot_dropped` signal, gray-box preview); click fires on release only for draggable slots (stations/hotbar keep instant press-fire). `GameState.move_slot(from,to)`: empty→move, same item→merge (overflow stays in source), different→swap. `BackpackPanel` enables drag on all 30 slots and routes drops; works across the hotbar↔backpack boundary; selection clears after a move.

_PAUSED after Step 6 (Step 7 deferred to M2). Steps 9–10 resume after the Spirit Garden epic._

- [ ] **7. External contextual drag (receiver-gated single item).** Retrofit the cook-station slot first as the reference receiver, then garden pot / spirit feed / fountain. ← NEXT

- [→] **8. Spirits tab — SUPERSEDED.** Reframed as a read-only **compendium** and folded into the Spirit Garden epic (G7); spirit→garden moved to the walkable garden scene (G3). See GARDEN.md.

- [ ] **9. Quests tab (active list → detail/rewards).**
- [ ] **10. Stubs wired: NPCs, Settings, Leave Game (Return to Title / Quit).**

**Step-3 deferred-but-flagged carryovers:** capacity-full UX (Step 5 Trash/notify; 30 slots won't fill in M1); cooking refund position-shift (last-of-stack then cancel re-places in first empty slot); items beyond slot 9 aren't hotbar-cookable until drag (Step 6).


## Active build order — Spirit Garden epic

Canon: GARDEN.md. Each item is its own teach-then-code step behind a Verify gate.

- [x] **G1. Spirit-as-entity migration.** Befriending writes a `kind: spirit` token (`add_spirit`, unique/non-stacking); `grant_starting_tools` seeds shovel + watering can (`kind: tool`) at new-game; both the hotbar and Backpack render all kinds; `Database.get_display_name` resolves spirits + a `tr()` fallback for tools (zh.po: 浇水壶/铲子); Trash blocks tools (spirits trashable).
- [x] **G2. Walkable garden scene.** `DayPhase.GARDEN` + `request_enter_garden` (ship Garden button rewired; hotbar shows here). `GardenScene` (gray-box room + rack, Leave→ship). New reusable **`PlayerCharacter`** (CharacterBody2D, side-scroll/top-down modes, flip walk/idle, collision shape) instanced as side-scroll Saff. `GardenPot` Control (gray-box, `set_spirit`) ×3 on the rack.
- [x] **G3. Planting drag.** Hotbar is now a drag source (`drag_enabled` decoupled from a new `click_on_release` flag, so cooking keeps instant press-staging). `GardenPot` is a receiver (`_can_drop_data`/`_drop_data`): drag a `kind: spirit` token onto an empty pot → `GameState.plant_spirit` moves it bag→pot (1 per pot). Persists across re-entry.
- [x] **G4. Tools + cursor-tool mode.** Clicking a hotbar tool toggles `SignalBus.tool_selected`; `UIManager.active_tool` holds it, shows a gray-box follow-cursor indicator (swatch + name), and auto-clears on phase change / pause-open. Right-click cancels; clicking an ingredient clears + stages. Cooking/planting unaffected.
- [x] **G5. Watering & yield.** `garden_slots` is now per-pot `{spirit, watered, progress}`. Watering-can spray (hold-LMB over pots) → `GameState.water_pot` (gray-box droplet). Day-end yield is gated: a watered pot banks `progress`; at `SpiritData.yield_interval_days` it produces (`produces × yield_per_night`) and resets; unwatered = paused (never dead); `watered` resets each day.
- [x] **G6. Removal — shovel hold-to-confirm.** With the shovel active, hovering a pot dims its spirit; `_process` accumulates a hold (~1s radial) that resets on release/move-off; completing calls `GameState.remove_potted_spirit` — permanent, no refund, `captured_spirits` untouched (stays depleted).
- [ ] **G7. Spirits compendium tab** (Pause Menu): codex grid + detail (Liked Food / Native Island / Production / Yield). Needs `SpiritData.native_island` + cadence. ← NEXT

- [ ] **G8. Rewire + cleanup:** ship-hub Garden button → the scene; discard the temporary `garden_panel`.




---

## Completed systems (done & verified)

- **Week 1 — daytime exploration (gray-box):** day-phase machine, ship hub, Kitchen (top-down), TopDownActor, Interactable/InteractionDetector. *(The original procedural exploration was later fully replaced — see below.)*
- **Week 2 / M1 — cook→deliver loop:** cooking sim (StationRecipe + intermediates + Dubious on mismatch), Recipe Book codex, Garden (assign spirit→pot→overnight yield; remove = permanent consume), Commissions + NPC delivery + CommissionHUD (soft-deadline additive bonus), Fair (tier-judged coins → rank).
- **Inventory-UX:** persistent 10-slot Quick Access hotbar (primary cooking surface); reusable `ItemSlot` + cursor tooltip; station cook-slots deduct-on-slot / refund-on-exit (`_exit_tree` catch); Fridge as paged grid + `fridge_storage`; number-key hotbar selection gated on station-open.
- **Cooking spice-constraint redesign (LOCKED):** tier = `clamp(2 + distinct compatible spices, 1, tier_cap)`; flavor-tag compatibility; set-aside (never wasted/Dubious); pipeline = only 5★ path. See DESIGN.md §3.
- **Open-book Fridge + Recipe Book:** shared hardened `BookFrame` (512×288), category bookmarks, info pages, visual recipe rows; driven by `CookingInfo`.
- **Exploration System Rework (all 9 steps COMPLETE):** Fuel+Time resources (fuel 6, node-driven time, 2 AM curfew, fuel-only gate); static fog-of-war Ocean Map of `WorldIslandData`; branching layered DAG via `RunGraphGenerator`/`RunGraph` held by `GameManager.run_graph`; previewable one-way path-map `IslandScreen` (fuel-on-entry, branch forfeit, loot-kept auto-return, capped 2 AM faint, manual retreat, overnight refuel/reset); DockNode; RewardNode + 3-mechanism Tier-S depletion (recipes/spirits/`island_depletion`) + 2× depleted terminal; SynergyEventNode (fungible-only buff, never Tier-S); **budget system deleted** + orphaned procedural classes removed; all-exits-to-ship + one-foray-per-day. See DESIGN.md §4, ARCHITECTURE.md §7–8.
**Localization (runtime i18n):** `LocaleManager` autoload (OS-default language, first-launch picker, persistent 语言 button, live switch, persisted to `user://settings.cfg`); Godot `TranslationServer` + `locale/zh.po`; ZCOOLKuaiLe CJK font as the project font. Standard: all player-facing strings via `tr()`/`tr_n()` with simultaneous `zh.po` entries. See ARCHITECTURE.md §11.

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
**Ship cabin interior** (`scenes/cabin/CabinLayout.tscn` + cabin art): artist-authored walkable ship-interior layout (rudder/oven/mixer/fridge in one room), currently **orphaned** — referenced by no script or scene. Parked as **M2 art**; does **not** override the locked "kitchen top-down forever" or "walkable ship deck + Captain's-room steering wheel = M2" decisions. Revisit when the M2 ship interior is actually designed.

---

## How to update this file (reminder for the AI)

After each completed + verified step: rewrite the **Current focus** + the build-order checkbox + move the finished item into **Completed systems** if it closes a system, and **append a dated entry to JOURNAL.md**. Hand Coda the updated content as a snippet (you are read-only) and remind them to commit.
