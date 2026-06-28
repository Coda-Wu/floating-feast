# GARDEN.md — *Floating Feast* Spirit Garden, Spirits-as-Entities & Tools

Canon for the spirit-garden loop, the spirit entity model, and player tools. Design only (what & why);
wiring lives in ARCHITECTURE.md, progress in STATE.md. Supersedes the temporary slot-based garden panel
and the original Pause-Menu "Step 8" (which assumed a management tab — now a compendium, see §7).

---

## 1. Purpose

The garden is the **grind-automation pillar** made tangible: tamed food-spirits work pots to yield
ingredients over time, so the player isn't forced to re-gather. It must stay **cozy and forgiving** —
no failure state, no punishment for neglect.

---

## 2. Spirits as entities (inventory tokens)

- Befriending a spirit in a `spirit_encounter` adds it to the **carried inventory as a `kind: spirit`
  token** (activating the content-agnostic slot model from DESIGN §7).
- Spirits are **unique and do not stack** — one token per species (capture still self-deduplicates).
- A spirit token can be carried, sorted, and dragged like any token. It is **plantable** (§4) and
  **release-able via Trash** (a backpack spirit may be trashed with the normal confirm — a second way
  to let one go), but tools are not (§6).

---

## 3. The Garden scene

- A **walkable 2D side-scroller** scene (not a menu panel, not top-down). Reached from the ship-hub
  **Garden** entry (rewired from the temporary panel, which is then discarded).
- **Pots sit on a rack.** M1 starts as a **single low row** (the existing 3 pots). The space is
  **vertically scalable** — a later upgrade path grows it into multi-tier "walls of pots."
- **One pot holds exactly one spirit** (1 slot = 1 spirit; no stacking).

---

## 4. Planting (drag from hotbar → pot)

- The player **drags a spirit token from the live hotbar onto an empty pot**. The pot is the
  receiver and **takes exactly one** (DESIGN §7's "receiver decides" contract — its real home).
- Dropping onto an occupied pot does nothing (one spirit per pot).

---

## 5. Watering & yield (forgiving)

- **Yield cadence:** a potted, watered spirit produces its ingredient **every 1–2 days** (per-spirit,
  from `SpiritData`). *(Replaces the old "overnight" rule in DESIGN §5.)*
- **Watering gates the cycle, never kills:** spirits must be watered **daily** to keep producing. If the
  player forgets, the yield cycle simply **pauses** — the spirit **does not die** — and **resumes** the
  moment it's watered again. This is the cozy-fail guarantee applied to the garden.
- **Watering can = a hotbar tool item** (§6): infinite, never refilled. Selecting it sets a watering
  cursor; **hold LMB to spray** across pots (a sweep waters every pot the cursor passes).
- *Default (flag to confirm):* a pot watered **at least once** on a given day counts as watered for that
  day's progress.

---

## 6. Tools (`kind: tool`)

- Tools are a distinct token kind (`{kind:"tool", id, count:1}`): **don't stack, persist forever,
  granted at new-game start**, and occupy normal hotbar/backpack slots.
- **Trash cannot delete a tool** (you can't lose your watering can); Sort clusters tools together.
- **Selecting a tool in the live hotbar enters a cursor-tool mode** (water / dig) instead of staging an
  ingredient; a normal (non-tool) hotbar click still stages for cooking as before.
- **M1 tools:** **Watering Can** (§5) and **Shovel** (§7-removal).

### Removal — Shovel "hold-to-confirm" (permanent)

- Select the **Shovel** → cursor becomes a shovel.
- **Hover an occupied pot** → the spirit dims/goes semi-transparent (it's targeted).
- **Hold LMB ~1s** → a radial progress UI by the cursor + digging SFX. **Release before it fills →
  fully cancels.** Complete → the spirit is **permanently deleted — no refund, it does NOT return to
  the backpack.** This preserves DESIGN §9's permanent-loss outcome via a forgiving gesture (no popup).

---

## 7. Spirits compendium (Pause-Menu tab)

- The **Spirits tab is a codex**, not a management surface — grid + detail like the Recipe Book.
- Per-spirit detail: **Liked Food, Native Island, Production Speed (cadence), Yield ingredient(s).**
- Requires new `SpiritData` fields (`native_island`, production cadence). Management (plant/water/remove)
  happens **only in the garden scene**, never in this tab.

---

## 8. Locked decisions (this system)

- Spirits are `kind: spirit` carried tokens; unique, non-stacking.
- Garden is a **walkable side-scroller scene**; planting is **hotbar→pot drag**; 1 pot = 1 spirit.
- Watering is a **forgiving pause** (never death); yield every 1–2 days, gated by daily watering.
- **Removal is permanent (no refund)** via the **shovel hold-to-confirm** (release cancels).
- Tools are `kind: tool` — granted at start, non-stacking, **trash-protected**, cursor-mode on select.
- The Spirits tab is a **compendium**; the temporary garden panel is **discarded** once the scene ships.

---

## 9. Deferred / M2

- Rack **upgrades** (multi-tier walls of pots) — the scaling path; M1 ships the single row.
- Additional tools / tool tiers; richer watering feedback; spirit happiness beyond water.
- Cross-doc impact to apply after this is approved: DESIGN §5 (yield/garden), §7 (spirits+tools in
  inventory), §9 (locked list); ARCHITECTURE (garden-slot per-pot state, `kind:tool`, `SpiritData`
  fields, garden scene, cursor-tool mode); STATE/JOURNAL (this epic replaces Pause-Menu Step 8).
