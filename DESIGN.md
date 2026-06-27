# DESIGN.md — *Floating Feast* Game Design Canon

The durable design decisions. This answers **"why is it built this way."** It changes only when a *design* decision changes — deliberately and rarely. Technical wiring lives in ARCHITECTURE.md; current progress in STATE.md.

---

## 1. Vision & pillars

A bright, whimsical, family-friendly **cozy roguelite** about cooking and sea adventure. Tension always resolves comedically; no failure is punishing. Touchstones: Stardew Valley, Dave the Diver, Spiritfarer, Slay the Spire, Coffee Talk; tonal vein of Animal Crossing / Pokémon.

- **Protagonist:** Saff, a new Explorer League recruit.
- **Ember:** a scripted hearth-spirit companion. Ember does **not** cook (sole exception to the wild-spirit rules).
- **M1 demo scope:** Cat Island only, Mediterranean cuisine.

**Three pillars:**
1. **Cooking is the deep mastery system** — the place skill expression lives.
2. **Exploration provides breadth** — varied islands, ingredients, encounters.
3. **Spirit companions automate grind** — tamed food-spirits work the garden overnight so the player isn't forced to.

---

## 2. The Commission Loop (the mandatory spine)

The coupling that holds the game together:

> **Calendar → Explore → Cook → Deliver at the Trade Fair → (rank up) → repeat.**

*Floating Feast* is a **coupled-loop game.** The Commission Loop is the mandatory spine; **expressive freedom lives *inside* the loop** (which cooking identity to build, which spirit roster to keep, how to plan a route), **not in bypassing it.**

- **Commissions are pull-based with soft deadlines.** On-time delivery grants a bonus; it **never gates** core progress. This preserves the cozy feel while keeping motivation.
- Delivering judged dishes at the Fair earns coins → **Explorer League rank**.

---

## 3. Cooking system (the deep system) — LOCKED

**Stations & pipeline.** Cooking is multi-station. The **Prep station** is a **1:1 batch transform**, *not* combinatorial recipe-matching: each slotted raw ingredient independently becomes its mid-stage product (e.g. 2 Potato → 2 Chopped Vegetable); items with no prep transform are left unconsumed. **Prep never outputs Dubious Food.**

**Tier formula:**
```
tier = clamp(2 + count of DISTINCT COMPATIBLE spices, 1, dish.tier_cap)
```
- Per-dish caps (`RecipeData.tier_cap`): roasts (tomato/potato/eggplant) & hummus = **3**, Classic Rustic Salad = **4**, Mediterranean Roasted Vegetables = **5**.
- Tier names: Plain / Good / Great / Perfect = 2 / 3 / 4 / 5★. **6★ is rejected** (max is 5).
- **The multi-station pipeline is the ONLY path to 5★ — that is its gameplay payoff.** It compresses many vegetables into a single terminal slot, freeing 3 slots for 3 spices. Design decisions should reinforce this clarity.

**Spice compatibility (flavor tags).** Each spice has `IngredientData.flavor_tags`; each dish has `RecipeData.accepted_flavors`. A spice helps **iff** their tags intersect.
- Tags: salt & onion = `savory`; rosemary = `herbal`; lemon = `citrus`; sugar = `sweet`.
- Accepted: roasts/medley = `[savory, herbal]`; salad = `[savory, herbal, citrus]`; hummus = `[savory, citrus]`.
- Spices that are **incompatible, a duplicate of an already-counted type, or beyond the dish's cap** are **set aside** (returned to inventory, no effect) — never wasted, never Dubious.
- **Sugar is currently orphaned** (matches no dish) until a sweet dish exists.
- A **required spice-tagged input** (e.g. lemon in hummus) is a **base ingredient**, not a bonus enhancer.

**Dubious Food** results **only** from genuine base-ingredient mismatches at the Mixing Bowl / Oven. It is rare and meaningful.

---

## 4. Exploration system (breadth) — LOCKED (rework complete)

Replaced the original procedural-island system. The macro-loop is now Fuel/Time-gated, branching, one-way, depth-tiered, depletion-capped, and cozy-fail throughout.

**Map.** A **static fog-of-war Ocean Map** of fixed, hand-authored **World Islands**. An island is unlocked when `quest_phase >= unlock_phase`. (Cat Island unlock 0 = always; Spice Isle phase 99 = fogged "to be continued.") The Ocean Map is reached **only** via a physical steering wheel in the Captain's room — there is **no map menu tab**.

**The run = a layered branching DAG**, regenerated each day from the island's pools: a single **start**, 3–4 branching middle layers (2–3 nodes each), a single **terminal**. Forward-only edges; the generator guarantees connectivity. The map is **fully previewable** up front.

**Resources & the central tension:**
- **Fuel is the ONLY strategic gate.** A node costs fuel on *entry*; the tank is one run's worth (refills overnight). Picking expensive (rich) nodes can strand you short of the terminal — **depth vs. breadth** is the core forfeit.
- **Time is the cozy wrapper, never a gate.** It advances on entry (≈1 hr/node) purely to flavor the day. The only time rule is the **2 AM curfew**: stepping past it auto-returns you (a capped coin loss only — never items/recipes/spirits/progress).
- **One-way commitment.** Choosing a branch **forfeits** the siblings for that run.
- **One foray per day.** Taking your first node commits the day's run to that island; it shows "Explored today" and can't be re-entered until dawn. (Closes the forfeit-bypass exploit.)

**Reward depth gradient.** Shallow nodes → renewable consumables. Mid → soft-build. Terminal → build-defining.

**Tier-S hard caps + permanent depletion** (the anti-grind ceiling):
- **Recipes** self-deplete via the learned flag (`known_recipes`).
- **Unique spirits** self-deplete via capture (`captured_spirits`).
- **Counted collectibles** (the geode) deplete via `island_depletion` (per-island cap, persisted).
- A **fully depleted island's terminal pays 2× the standard consumable reward**, maintaining engagement. This makes the demo's content **finite by design** — the demo ends on the *main quest*, not on grind.

**Node types (7):** gathering, spirit_encounter, shop/butchery, npc, event, **dock** (the only in-run refuel: +1–3 fuel, net 0/+1/+2 after its entry cost), **reward** (terminal prizes). Plus a within-run **synergy "Hidden Shrine"** (shallow-only, ≤1/run): sacrifice coins or fuel for a run-scoped buff that doubles **fungible** yields — **provably never** multiplies capped Tier-S.

---

## 5. Spirits & garden

- Food-spirits are tamed in `spirit_encounter` nodes (feed raw ingredients to easygoing spirits; tougher ones have requirements).
- Tamed spirits are **assigned to garden pots** to produce ingredients **overnight** (the grind-automation pillar).
- **Removing a spirit from a pot permanently consumes it** (gone from the roster, not returned).
- The **food → Ember firewall:** food never refuels Ember. If mining/fishing are later added as free on-ship activities, their rewards stay consumable-tier; nothing there feeds the hearth-spirit. This keeps fuel a pure exploration resource.

---

## 6. Soft-fail philosophy (cozy guarantees)

Every exit path preserves collected loot. The 2 AM faint is capped at a small coin loss only. Run buffs always clear on exit. Systemic safety nets prevent feel-bad moments. **No failure state is punishing.**

---

## 7. Inventory & menu UX (design intent)

- A persistent **10-slot Quick Access hotbar** is the primary cooking-ingredient surface (Ship + Kitchen only). It is **row 0 of the carried inventory.**
- A **Universal Pause Menu** (Stardew-style, `Esc`-opened) is the all-in-one screen: Backpack (inventory + player profile), Spirits, NPCs, Quests, Settings, Leave Game. **No map tab.**
- The carried inventory is a **slot-ordered, content-agnostic** model: slots will eventually hold ingredients, dishes, spirits, ore, geodes, and furniture — not just ingredients.
- **Player Name & Ship Name are player-set at the start of a new game** (Stardew-style onboarding, planned for M2). They are real fields the menu reads — **never hardcoded.**
- Drag model: **default = full stack** (rearrange); **contextual = receiver-gated single item** (dropping onto a cook station / garden pot / spirit / fountain takes exactly one; the "only one" rule lives in each *receiver*).

---

## 8. Documentation & content conventions (design-facing)

- **One file per system.** New systems/scopes never fold back into a monolith.
- **Swap-linchpin rule:** no scene or script hard-references final art/audio. Everything is gray-box-first; Week-3 is a pure asset swap. (See ARCHITECTURE.md for the mechanism.)
- Design docs are delivered in **English and Simplified Chinese** when authored as standalone deliverables (game-dev terminology kept in English in the CN version; no em-dashes; cultural references localized).

---

## 9. Locked decisions (do not revisit without instruction)

- Prep = 1:1 batch transform; never Dubious.
- Cooking tier = spice-compatibility formula (§3).
- Slots reserve→deduct-on-slot / refund-on-exit (cooking stations).
- Commission deadlines additive-only (never gate).
- Garden removal permanently consumes the spirit.
- Kitchen is top-down forever (any side-scroller art is throwaway).
- Single dish store (no carried/stored split; dishes "travel with you").
- Modular docs (new systems → standalone files).
- **Exploration rework complete:** fuel = 6, node-driven time, RunGraph/WorldIslandData, budget system deleted, one-foray-per-day, all-exits-to-ship.
- **Pause Menu:** slot-ordered tagged-token inventory; receiver-decides drag; full-screen frame (not the BookFrame); content-agnostic slots; Name/Ship as real fields.

---

## 10. Key learnings & principles (carry forward)

- **Multi-station pipeline as gated reward:** the payoff is ingredient compression freeing spice slots — the reason it's the only 5★ path.
- **Fuel = the only gate; time = ambient.** Conflating them would undermine both feelings.
- **Tier-S caps + 2× depleted terminal** prevent infinite farming while keeping engagement.
- **Deduction-on-slot / refund-on-exit**, with `_exit_tree` as the universal refund catch.
- **Dubious Food is rare and meaningful** — only genuine base mismatches trigger it.
- **The coupled loop is sacred:** expressive freedom lives *inside* the Commission Loop, not in bypassing it.
