# JOURNAL.md — *Floating Feast* Milestone History

**Append-only.** Never edit past entries; only add new ones at the top of the log. One short entry per milestone: what changed, what was decided, what was deferred and why. When STATE.md ever drifts from reality, this is the reconstruction source.

**Entry format:**
```
## YYYY-MM-DD — <milestone title>
- Changed: …
- Decided: …
- Deferred: …
- Verified: …
```

---

## 2026-06-28 — Spirit Garden G1: entity-token migration complete

- **Changed:** `GameState` gained `add_spirit(id)` and `grant_starting_tools()` over a shared `_add_unique_token(kind,id,emit)` (unique, non-stacking). `GameManager._seed_new_game` grants `watering_can` + `shovel` (`kind: tool`). `spirit_encounter._succeed` writes a `kind: spirit` token on first capture (alongside the `captured_spirits` ledger). Both `quick_access_bar.refresh` and `backpack_panel.refresh` now render any token kind. `Database.get_display_name` resolves spirits and falls back to a `tr()`-able capitalized id (covers tools); zh.po got 浇水壶/铲子. Backpack Trash is gated by `_can_trash` (blocks `kind: tool`; spirits/items allowed).
- **Decided:** `captured_spirits` stays the permanent "ever-caught" depletion ledger; the spirit *token* is the physical holding (trashing/removing a spirit is permanent — the ledger keeps the species depleted). Starting tools land in the backpack (hotbar is full of seeded ingredients) — curate later if needed.
- **Deferred:** Cursor-tool mode (G4) — clicking a tool in the hotbar currently does nothing (station rejects non-ingredients).
- **Verified:** Tools render in the backpack (names localize); Sort clusters item→spirit→tool; tools can't be trashed, spirits can; capture wiring mirrors the G1a-tested `add_spirit`.


## 2026-06-28 — Spirit Garden epic scoped; Pause-Menu Step 8 reframed

- **Changed (design):** Authored GARDEN.md — canon for the spirit-garden loop, spirits-as-entities, and tools. Updated DESIGN.md §5 (garden), §7 (inventory kinds), §9 (locked list) to point to it.
- **Decided:** Spirits become `kind: spirit` carried tokens (unique, non-stacking). The garden is a walkable 2D side-scroller scene (pulled forward from M2); planting = hotbar→pot drag; yield every 1–2 days gated by daily watering, a forgiving pause (spirits never die). Removal is permanent (no refund) via a shovel hold-to-confirm gesture (preserving §9's outcome). Tools are a new `kind: tool` (shovel + watering can; granted at start, non-stacking, trash-protected, cursor-mode on select). The Pause-Menu Spirits tab is now a read-only compendium — the original Step 8 is superseded and folded into the epic (G7); spirit→garden drag moves to the garden scene (G3).
- **Deferred:** Rack upgrades / walls-of-pots (M2); Pause-Menu Steps 9–10 (Quests, stubs) resume after the epic; external item-drag (Step 7) stays M2.
- **Verified:** GARDEN.md committed; design grounded against the existing spirit model (`captured_spirits`, `garden_slots`, `SpiritData`) and the §7 token model.



## 2026-06-28 — Pause Menu Step 6: intra-grid drag-and-drop complete

- **Changed:** Made `ItemSlot` drag-capable via Godot's built-in drag (`_get_drag_data`/`_can_drop_data`/`_drop_data`), gated behind an opt-in `drag_enabled`; each slot carries `_slot_index`, emits `slot_dropped(from,to)`, and shows a gray-box `ColorRect` preview. Click now fires on **release** for draggable slots only (non-draggable stations/hotbar keep instant **press**-fire). Child swatch/labels set `mouse_filter = IGNORE` so the Panel owns mouse/drop across the whole cell. New `GameState.move_slot(from,to)` — empty→move, same `(kind,id)`→merge (overflow stays in source), different→swap; emits `inventory_slots_changed` only (totals unchanged). `BackpackPanel` enables drag on all 30 slots, stamps indices, and routes drops; selection clears after a move.
- **Decided:** Built-in drag over a manual implementation; release-fire **gated to draggable slots** (stations need instant press feedback); drag works across the hotbar↔backpack boundary (consistent with sort-all-30).
- **Deferred:** External contextual drag onto receivers (Step 7); a drag-onto-trash target.
- **Verified:** Move/swap/merge all correct, cross-boundary drag works, plain click still selects (on release), selection clears post-drag, live hotbar reflects the new row-0 layout on close, layout persists across reload; station/hotbar press-clicks unchanged.


## 2026-06-28 — Pause Menu Step 5: Auto-Sort + Trash complete

- **Changed:** Added a right-aligned `Sort`/`Trash` toolbar to `BackpackPanel` (localized 整理/丢弃). New `GameState.sort_inventory()` — merges same-`(kind,id)` stacks, orders by type (`tags[0]` then display name, items before spirits), splits over-`STACK_MAX` stacks, and compacts all 30 slots. New `GameState.clear_slot(i)` (emits via `_emit_inventory_changed`). Trash flow reuses the Step-4 selection: button enables only when a slot is selected → confirm → delete. Made the shared `WarningPopup` `PROCESS_MODE_ALWAYS` so the confirm stays clickable over the paused menu. Fixed the latent 4b bug (the `slot_clicked` connect was inside the row-0 `if` block — now all slots are selectable).
- **Decided:** Auto-Sort reorganizes **all 30 slots** (hotbar included; re-curate via drag in Step 6). Trash is **select + button + confirm** — no drag this step; a drag-onto-trash target can come with Step 6/7.
- **Deferred:** Drag (Step 6); a drag-to-trash drop target; capacity-full *auto-notify* (Trash now gives manual relief; 30 slots still won't fill in M1).
- **Verified:** Sort merges/reorders/compacts and is idempotent; backpack-row items are now selectable; Trash greys until selection, confirm renders above the paused menu and is clickable, deletion persists across reload; all strings localize; the island voluntary-exit confirm still works.


## 2026-06-28 — Pause Menu Step 4: selection primitive complete

- **Changed:** Added `ItemSlot.set_selected(bool)` (promoted the slot's gray-box `StyleBoxFlat` to a member `_panel_style`; `BORDER_DEFAULT`/`BORDER_SELECTED` consts; red 2px outline on select). `BackpackPanel` now tracks a single `_selected_index` via a `_select()` helper — click (`slot_clicked`) or number keys `1–0` (row-0 slots, reusing the `hotbar_*` input actions, `visible`-gated to the active tab) outline one slot at a time; re-selecting toggles it off; both inputs share the same state.
- **Decided:** Selection is **highlight-only groundwork** and **menu-local** — it clears on menu close (panel is rebuilt per open) and the live hotbar→cooking staging is untouched. Filled slots only (empty cells become selectable when they're drop targets in Step 6).
- **Deferred:** Auto-sort + trash (Step 5); intra-grid drag swap/merge (Step 6); clearing selection when the selected slot empties (relevant once Step 6 mutations land).
- **Verified:** Click and number keys both drive a single red outline; toggling, tab-gating, and keys-while-paused all confirmed working; cooking number-keys still work after closing the menu.



## 2026-06-28 — Pause Menu Step 3: Backpack tab (grid + profile) complete

- **Changed:** Added `GameState.player_name`/`ship_name` as real serialized fields (defaults Saff / "Saff's Ship"; M2 onboarding will overwrite). New `BackpackPanel` scene+script: upper-half 10-col grid of 30 `ItemSlot`s bound to `GameState` slots by index (row 0 = hotbar w/ hotkeys 1–0; refreshes on `inventory_slots_changed`); lower-half profile (gray-box `ColorRect` portrait + Name/Ship/Coins/Rank from the real fields). `pause_menu.gd` swaps its tab-0 placeholder for the panel. Localized the profile strings + all six tab labels in `zh.po` (reused `精灵` for Spirits, `等级`/`金币` for Rank/Coins). Made the menu a proper top modal: `UIManager` hides HUD+hotbar on open and restores them phase-aware on close (+ `hide_item_tooltip`); `ItemTooltip` now `PROCESS_MODE_ALWAYS` so it follows the cursor while paused.
- **Decided:** HUD/hotbar are hidden while the pause menu is open (Stardew-style top modal) rather than raising the menu's layer. Grid is display-only this step — clicks/selection → Step 4, drag → Step 6. `NPCs` tab localized as `角色` (confirm later if a different term is preferred).
- **Deferred:** Selection + number-key highlight (Step 4); auto-sort + trash (Step 5); intra-grid drag (Step 6); capacity-full UX (Step 5).
- **Verified:** Backpack grid mirrors the hotbar; profile reads real fields and localizes; opening the menu hides HUD+hotbar and the tooltip renders above the menu and tracks the cursor (Coda confirmed the pre-fix HUD/hotbar overlap). **Drift corrected:** `PersistentUI` (layer 128) was always above `PauseMenu` (layer 5) — STATE's "menu sits above the tooltip" note was stale; the tooltip was never occluded.


## 2026-06-27 — Doc reconciliation: i18n system documented; cabin art parked

- **Changed (docs only):** ARCHITECTURE §3 now lists Dialogic (plugin autoload, registered first) + LocaleManager (11th autoload) and corrects the Database filename to `data_base.gd`; added ARCHITECTURE §11 documenting the runtime localization pipeline. STATE: added Localization to Completed systems; parked the orphaned `scenes/cabin/CabinLayout.tscn` under Deferred threads.
- **Decided:** the i18n system (LocaleManager + zh.po + TranslationServer + ZCOOLKuaiLe font) is canon and matches CLAUDE.md's strict-L10n standard. The cabin art drop stays parked M2 — it does NOT override "kitchen top-down forever" or "walkable ship = M2".
- **Deferred:** wiring the cabin interior; Dialogic narrative (M2).
- **Verified:** code is the source of truth — both autoloads confirmed in project.godot; cabin scene confirmed orphaned (no references). No code changed.


## 2026-06-27 — Workspace seeded; transitioned from web chat to Claude Code

- **Changed:** Created the five-file doc set (CLAUDE.md, DESIGN.md, ARCHITECTURE.md, STATE.md, JOURNAL.md) to move project state out of a long, degrading web-chat into version-controlled files. Established **tutor / read-only** enforcement (permission denylist + `PreToolUse` guard hook + CLAUDE.md role) and safety hooks (no destructive commands, no editing outside the project folder).
- **Decided:** The AI operates as a mentor only — it reads/inspects and hands Coda snippets to apply by hand; it never writes project files. Stateful workflow: read STATE.md at session start, update STATE.md + append here after every milestone.
- **Deferred:** Nothing new; carried the existing deferred-threads list into STATE.md.
- **Verified:** Transition made on a clean boundary — Pause-Menu **Step 2 done & verified, Step 3 not started.** First local task is the doc seeding itself, then resume at Step 3.



---

## (reconstructed) — Project history to date

A condensed log of the journey before the workspace transition. Exact dates weren't tracked in the chat; this is a single reconstructed summary so the *reasoning* is recoverable. Future entries will be properly dated per milestone.

**Week 1 — daytime exploration (gray-box).** Built the day-phase machine, ship hub, top-down Kitchen, TopDownActor, Interactable/InteractionDetector. Established the SignalBus-only + autoload architecture and the gray-box-first / swap-linchpin discipline.

**Week 2 / M1 — cook→deliver loop.** Cooking sim (StationRecipe + intermediates `chopped_vegetable`/`oiled_vegetable` + Dubious-on-mismatch), Recipe Book codex, Garden (assign spirit→pot→overnight yield; remove permanently consumes), CommissionData/CommissionManager + NPC delivery + CommissionHUD (soft-deadline additive bonus), Fair (tier-judged coins → Explorer League rank). Locked: soft deadlines never gate; garden removal consumes; kitchen top-down forever.

**Inventory-UX.** Persistent 10-slot Quick Access hotbar as the primary cooking surface; reusable `ItemSlot` (swatch / count-hidden-at-1 / hotkey / star) + cursor-following tooltip; station cook-slots **deduct-on-slot / refund-on-exit** with `_exit_tree` as the universal refund catch; Fridge rebuilt as a paged grid backed by `fridge_storage`; number-key hotbar selection gated on station-open. Decided: deferred full Backpack + drag-and-drop.

**Cooking spice-constraint redesign (superseded the old tier rule).** Locked `tier = clamp(2 + distinct compatible spices, 1, dish.tier_cap)`; flavor-tag compatibility (savory/herbal/citrus/sweet); incompatible/duplicate/over-cap spices are **set aside** (never wasted, never Dubious); the multi-station pipeline is the only path to 5★ (its payoff = ingredient compression freeing spice slots). Sugar orphaned until a sweet dish exists. Prep confirmed 1:1 batch transform, never Dubious.

**Open-book Fridge + Recipe Book.** Both rebuilt on a shared hardened `BookFrame` (fixed 512×288, both-axis-scroll pages, reserved 28px side column, swappable background), driven by the `CookingInfo` static helper. Fridge: category bookmarks + info page; Recipe Book: visual recipe rows (ingredient → station → output icons) + compatible-spice row.

**Exploration System Rework (9 steps, complete) — the big one.** Replaced the original procedural-island system end to end:
- *Resources:* Fuel (max 6, the only gate) + Time (node-driven, 6 AM→2 AM curfew, cozy wrapper, never gates).
- *Map:* static fog-of-war Ocean Map of hand-authored `WorldIslandData` (Cat Island unlock 0; Spice Isle phase 99 fogged).
- *Run:* branching layered DAG via `RunGraphGenerator` → `RunGraph` (connectivity-guaranteed, per-node `fuel_cost`), held by `GameManager.run_graph`, generated in `enter_world_island`.
- *Traversal:* `IslandScreen` rewritten as a previewable one-way path-map — fuel paid on entry, branch siblings forfeited, loot-kept auto-return on terminal/fuel-out, capped 25-coin 2 AM faint → ship, manual retreat, overnight refuel + clock reset.
- *Nodes:* DockNode (only in-run refuel, net 0/+1/+2); RewardNode + Tier-S depletion via 3 mechanisms (recipes→`known_recipes`, unique spirits→`captured_spirits`, geode→`island_depletion`, serialized) + fully-depleted island pays 2× standard terminal; SynergyEventNode "Hidden Shrine" (shallow-only, ≤1/run; sacrifice coins/fuel → run buff doubling **fungible** yields only, provably never Tier-S via the `tier_s_id` guard; cleared on every exit).
- *Cleanup:* budget system fully deleted; `Island`/`IslandArranger`/`TravelRoute`/`NodeChainGenerator`/`IslandMarker` removed; all run exits → ship; one-foray-per-day (`islands_explored_today`) closes the forfeit-bypass exploit. `IslandTemplate`/`_gen_islands` left unused-but-harmless.
- *Result:* the demo's content is finite by design — it ends on the main quest + fogged Island 2, not on grind.

**Universal Pause Menu — scoped & started.** Scoped up from "Backpack" to a Stardew-style all-in-one `Esc` menu (Backpack / Spirits / NPCs / Quests / Settings / Leave Game; **no map tab** — Ocean Map only via a future Captain's-room steering wheel). Locked: Esc pauses the tree; modal-registry gating; full-screen frame (not BookFrame); receiver-decides drag; content-agnostic slot model (`{kind,id,count}`); Name/Ship as real player-set fields.
- *Step 1 done:* PauseMenu shell + `UIManager` modal registry + Esc gating + tab switching.
- *Step 2 done:* migrated carried inventory from `{id:count}` dict to the 30-slot tagged-token array (hotbar = row 0), ID API preserved as a compatibility layer, new `inventory_slots_changed` signal, serialize + legacy-save migration, `QuickAccessBar` repointed to row 0 (pagination removed).
- *Next:* Step 3 — Backpack static layout + profile + `player_name`/`ship_name` fields.
