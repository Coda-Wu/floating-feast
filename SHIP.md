# SHIP.md — Floating Feast Ship Interior & Day Loop

Canon for the walkable ship interior (Cabin + Captain's Room), room transitions, and the day loop.
Design only; wiring in ARCHITECTURE.md, progress in STATE.md. Supersedes the button-based ShipScreen
and the top-down KitchenScene (DESIGN §9 reversal: the ship interior is side-scrolling).

## 1. Scenes
- **Cabin (main hub)** — side-scroller. Holds the kitchen (cook stations as walk-up/press-E
  interactables), two doors, and a right-edge transition zone.
  - Side door → press E → Spirit Garden.
  - Right edge (collision zone) → Captain's Room.
  ## 1a. Layout coordinates (M1)
- **Cabin** — Garden door center x=640 (half off-screen → nudges exploration); Carpet center x=770, its right side (~x=800) is the transition zone → Captain's Room.
- **Captain's Room** — Exploration door on the left → Set Sail. Bed in the middle-left (confirm end day). Steering Wheel on the right  → view Ocean Map.
- **Return spawn (Captain→Cabin):** x∈(640, 770), e.g. ~700 — left of the carpet, right of the garden door.

## 2. Movement & transitions
- One reusable `PlayerCharacter` (CharacterBody2D) per scene; each room has a Camera2D that follows it.
- A `Transitions` autoload: fade-out → `change_scene_to_file` → spawn at a named marker → fade-in.
- Doors transition on E-press; room edges transition by walking into a collision zone.

## 3. Interactables (press-E)
- Cook stations (prep / mix_bowl / oven) → StationUI (as today). Fridge / Recipe Book → as today.
- Center door → sail; side door → garden; Steering Wheel → Ocean Map; Bed → end day (with confirm).

## 4. Day loop
- **Morning** spawns in the **Captain's Room** (by the Bed / Sail Door), ready to move.
- **Exploration returns to the Cabin** (the hub). Sailing departs from the Captain's Sail Door.
- **Time** flows normally inside the ship (1 second = 1 in-game minute); At 2 AM the game forces the player to bed.
- **Ocean Map** only via the Steering Wheel (DESIGN §4) — no auto-entry at exploration start. Using the map
  to jump between big islands costs one full in-game day (future).
- **End of day:** press E on the Bed (confirm) → resolve overnight (garden yields, etc.) → next morning in the Cabin.

## 5. Trade Fair
- Becomes a daytime-exploration **node** on certain dates (e.g. weekly); not refined yet. The old
  ShipScreen Fair button is dropped (FairScene temporarily unreachable).

## 6. Locked decisions
- Ship interior is side-scrolling; kitchen is in the Cabin (reverses "kitchen top-down forever").
- One reusable `PlayerCharacter`; rooms via `Transitions` autoload + per-room Camera2D + spawn markers.
- Ocean Map only via the Steering Wheel; Bed ends the day; morning spawns in the Cabin (no menu).
- No `placeholder/`+`final/` asset mirror — single final copy (see ASSETS.md).

## 7. Deferred / TBD
- Prep-station art; exact time-flow rate + curfew interaction (Phase 4); map-jump-costs-a-day; Fair node;
  Z-layering polish (Phase 5); Kitchen→PlayerCharacter migration specifics.
