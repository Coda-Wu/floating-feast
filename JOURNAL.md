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
