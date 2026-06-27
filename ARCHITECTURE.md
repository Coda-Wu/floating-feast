# ARCHITECTURE.md — *Floating Feast* Technical Map

How the code is wired, so any code you propose **fits this project's conventions** instead of generic Godot. Changes only when the *structure* changes (a new autoload, a new core class). Design lives in DESIGN.md; progress in STATE.md.

---

## 1. Engine & target

- **Godot 4.6**, GDScript.
- Base resolution **640×360**, pixel-perfect integer scaling. Steam target (mouse + keyboard).

---

## 2. Core principles (the rules every change obeys)

1. **Systems talk ONLY via the SignalBus + autoloads.** No system reaches into another's nodes.
2. **One scene per UI / node.** Each screen, panel, and exploration node is its own scene.
3. **All content lives in `.tres` Resources**, indexed by `Database` at boot.
4. **Swap-linchpin rule.** No scene/script hard-references final art/audio; assets are assigned at runtime from `Database` (placeholder/final mirror), so Week-3 is a pure asset swap.
5. **No speculative abstraction.** Build the simplest thing the current step needs.
6. **Every `GameState` mutator emits its own change signal.** UI subscribes to state-change signals and refreshes passively — never polls.

---

## 3. Autoloads (singletons) — dependency order

Defined in `src/autoload/`, snake_case filenames. **Autoloads have NO `class_name`** (the global is the autoload name). The **Dialogic** plugin registers its own autoload *first* (before SignalBus); it's an addon, not one of our singletons — see §10. Our singletons load in this dependency order:

1. `signal_bus.gd` — **SignalBus.** Global signal hub; the only cross-system channel.
2. `data_base.gd` — **Database.** Scans `resources/`, indexes every `.tres` by `id`, halts on duplicate ids. Final-first asset resolver.
3. `game_state.gd` — **GameState.** The runtime model: pure data + persistence + thin mutators that emit signals. **No gameplay rules.**
4. `audio_manager.gd` — **AudioManager.**
5. `scene_router.gd` — **SceneRouter.**
6. `ui_manager.gd` — **UIManager.** Owns `PersistentUI` (HUD + hotbar); owns the modal registry + pause-menu gating.
7. `tutorial_manager.gd` — **TutorialManager.**
8. `quest_manager.gd` — **QuestManager.**
9. `commission_manager.gd` — **CommissionManager.**
10. `game_manager.gd` — **GameManager.** Day-phase machine + run orchestration.
11. `locale_manager.gd` — **LocaleManager.** Runtime language handling (registered last; adds no dependency to game scenes). See §11.

---

## 4. Communication: the SignalBus

All inter-system events flow through `SignalBus`. Key signals (non-exhaustive):
- Inventory: `inventory_changed(id, count)` (ID consumers) · `inventory_slots_changed()` (positional consumers — hotbar/backpack) · `fridge_changed()` · `dish_inventory_changed()`.
- Economy/progress: `coins_changed(coins)` · `rank_changed(rank)` · `recipe_discovered(id)`.
- Exploration: `fuel_changed(cur, max)` · `time_changed(minutes)` · `day_auto_returned(reason)` · `run_buff_applied(buff)` · `node_started(def)` · `node_resolved(def, rewards)` · `island_exited()`.
- UI/flow: `day_started(day)` · `station_ui_opened()` / `station_ui_closed()` · `hotbar_item_selected(id)`.

> `island_entered(island)` is a **dead declaration** (zero consumers after the exploration rework) — harmless; left in place.

---

## 5. Directory layout (under `res://`)

```
src/
  autoload/    # the singletons above
  core/        # RunGraph, RunGraphGenerator, Cooking, CookingInfo, ...
  data/        # Resource classes: NodeDefinition, WorldIslandData, IngredientData, RecipeData, ...
  ui/          # ItemSlot, ItemGrid, BookFrame, Bookmark, QuickAccessBar, FridgeUI, RecipeBookUI, PauseMenu, ...
  screens/     # OceanMapScreen, IslandScreen, KitchenScene, FairScene, ...
  nodes/       # ExplorationNode + concretes: DockNode, RewardNode, SynergyEventNode, SpiritEncounterNode, ...
scenes/        # .tscn mirrors: main/ screens/ ui/ nodes/ components/
resources/     # authored .tres content (scanned by Database)
tools/         # generate_week1_content.gd (EditorScript: File → Run to author .tres)
assets/        # placeholder/ + final/ mirror; final-first resolver in Database
```

**Naming:** snake_case script filenames; **PascalCase `class_name`** inside (except autoloads); PascalCase `.tscn`; snake_case folders. Asset names use category prefixes + snake_case, subject matching the data Resource `id`.

**Content authoring:** `res://tools/generate_week1_content.gd` is an `EditorScript` (File → Run) that rewrites `.tres`. After changing pool/recipe data, re-run it.

---

## 6. Inventory data model (current — the slot-ordered token array)

`GameState.inventory` is a **fixed-length `Array`** of tagged tokens:
- Each cell is `null` (empty) **or** `{ kind: StringName, id: StringName, count: int }`.
- `kind` is `&"item"` today; `&"spirit"` and future kinds (ore/geode/furniture) drop in with **no model change** (content-agnostic by design).
- Length = `HOTBAR_SLOTS(10) + BACKPACK_ROWS(2)×SLOTS_PER_ROW(10)` = **30**. `STACK_MAX = 999`.
- **Slots 0–9 = hotbar row 0.** The on-screen `QuickAccessBar` renders those exact indices (no pagination), so slot positions are stable — the prerequisite for drag.

**Compatibility layer:** the ID-based API is preserved *over* the array, so cooking/fridge/reward callers are untouched:
- `add_item(id, count)` — stack onto a matching token, else first empty slot; emits both inventory signals.
- `remove_item(id, count) -> bool` — remove across slots, clearing emptied cells.
- `get_item_count(id) -> int` — sum across slots.
- Positional accessors: `get_slot(i)`, `slot_count()`, `get_carried_item_ids()`.
- `serialize`/`deserialize` round-trip the array; `deserialize` also migrates legacy `{id:count}` saves.

Parallel stores: `fridge_storage` (`{id:count}`, home overflow) and `dish_inventory` (`"recipe_id|tier" -> count`, the single dish store — dishes travel with the player).

---

## 7. Key classes & contracts

- **`ExplorationNode`** (base, `src/nodes/`) — contract every node implements: `start(def)` sets `node_def` then calls `_run()`; the node eventually calls `complete(rewards, outcome_text)` → emits `node_completed`. `IslandScreen` instantiates the node into a slot, connects `node_completed`, calls `start(def)`.
- **`NodeDefinition`** (`RefCounted`) — `type: StringName`, `params: Dictionary`, `fuel_cost: int`. `_init(type, params)`.
- **`RunGraph`** (`src/core/`) — one day's DAG: `nodes[]`, `edges` adjacency, `layer_of[]`, `start_index`, `terminal_index`; helpers `next_of`, `incoming_count`, `layer_count`, `nodes_in_layer`. Held by `GameManager.run_graph`.
- **`RunGraphGenerator`** — `generate(world_island, seed) -> RunGraph`. Layered, connectivity-guaranteed; `_eligible()` excludes learned recipes / captured spirits / depleted Tier-S; depleted island → 2× standard terminal.
- **`WorldIslandData`** (`Resource`) — `id`, `display_name`, `cuisine`, `unlock_phase`, `map_position`, `shallow_pool` / `mid_pool` / `deep_pool` (each `{type, params, weight?, fuel_cost?}`), `tier_s_caps`, `standard_terminal_reward`.
- **`ItemSlot`** (`src/ui/`, `class_name`) — reusable gray-box slot: center swatch (`color_for(id)`, Week-3 sprite target), count bottom-right (hidden at 1), optional hotkey bottom-left, optional star overlay. Signals `slot_clicked(item_id)`.
- **`ItemGrid`** (`class_name`) — paged grid of `ItemSlot`s (never scrolls on the selection side).
- **`BookFrame`** (`class_name`) — hardened open-book chrome, **fixed 512×288**, both-axis-scroll pages, reserved 28px side column, swappable background. Consumers: Fridge, Recipe Book (and a future Backpack/Quest/Map/NPC book — *separate* from the full-screen Pause Menu frame).
- **`CookingInfo`** (`src/core/`, static helper) — recipe-step queries with demand-propagated counts, base ingredients, compatible spices, dishes-using-an-ingredient.
- **`UIManager`** modal registry — `register_modal(self)` / `unregister_modal(self)` (in `_exit_tree`) / `is_modal_open()`; `_unhandled_input` routes `Esc` (open pause menu if no modal; close it if it's open; ignore if a dedicated UI owns the screen). PauseMenu `CanvasLayer` is `PROCESS_MODE_ALWAYS`; opening sets `get_tree().paused = true`.

---

## 8. Day-phase machine (`GameManager`)

`DayPhase`: MORNING → OCEAN_MAP → ISLAND → SHIP → KITCHEN → FAIR → DAY_END. `change_phase` emits `phase_changed` and loads the screen. `start_day()` rolls seed/weather, **refuels Ember to full + resets the clock to 6 AM**, clears `islands_explored_today`. `enter_world_island(wi)` sets `current_world_island` + builds `run_graph` via `RunGraphGenerator`, → ISLAND. **All run exits return to the ship.**

> Removed in the exploration rework (do not resurrect): the budget system, `IslandArranger`, `TravelRoute`, `NodeChainGenerator`, `Island`, `IslandMarker`, and procedural day-island generation. `IslandTemplate` + `_gen_islands` survive as unused-but-harmless (still Database-indexed); broader cleanup deferred.

---

## 9. Asset pipeline

`res://assets/` with a `placeholder/` ↔ `final/` mirror structure. Database's resolver returns final when present, else placeholder. Gray-box-first build order; later weeks are a pure swap. **No scene or script names the final asset directly.**

---

## 10. Other tools

- **Dialogic** for NPC dialogue (signal pattern retained from prior architecture). Reserved for M2 narrative work.

## 11. Localization (runtime i18n)

The game ships English + Simplified Chinese, switchable live.

- **`LocaleManager`** (autoload, no `class_name`) — defaults to the **OS language**, shows a **first-launch language picker**, and mounts a persistent **"语言" button** (its own `CanvasLayer`, layers 127/128) so the player can re-pick anytime. `set_language("zh"/"en"/"system")` switches live; the choice persists to `user://settings.cfg` under `[locale]/language`. `SUPPORTED = ["zh","en"]`, fallback `en`. It builds its UI in code, so it touches **no** game scene.
- **Translation source:** Godot's `TranslationServer` + `res://locale/zh.po`, registered in `project.godot` under `[internationalization] locale/translations`.
- **Font:** `assets/fonts/ZCOOLKuaiLe-Regular.ttf` is set as `gui/theme/custom_font` for CJK glyph coverage.
- **Coding standard (mirrors CLAUDE.md):** every player-facing string goes through `tr()` / `tr_n()`; every new English key gets its `zh.po` Chinese counterpart **in the same pass** — no untranslated player-facing English in a code change.