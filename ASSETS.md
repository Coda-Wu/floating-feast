# ASSETS.md — Floating Feast Asset Pipeline & Naming

Single source of truth for asset naming, format, and import. Adapted from the naming deck to
**single-copy assets (no placeholder/final mirror)** — everything is treated as final.

## 1. Principle
A stable name + a matching shape = a clean swap. Replace a gray-box file in place with final art of the
**same path, dimensions, sheet grid, pivot, 9-slice margins, and audio role** — no scene edits needed.
Database-bound icons/sprites resolve by logical key (subject = data Resource id).

## 2. Filename anatomy
`prefix_subject[_descriptor][_NN]` — lowercase snake_case, ASCII, no spaces/caps/version words.
- **Subject = the data Resource id** for anything Database binds (icons, ingredient/spirit sprites).
- Direction tokens `_down _up _left _right`; sequences zero-padded `_01 _02 …`. No `_final`/`_v2`/`_new`.

## 3. Prefixes
chr_ · npc_ · spirit_ · por_ · ico_ (ingredient/dish/item/node/ui) · ui_ (panel/button/hud/cursor) ·
bg_ · tile_ · prop_ (scenery & stations) · map_ · fx_ · sh_ · bgm_ · amb_ · sfx_.

## 4. Formats & import
- Art `.png` only (never `.jpg`). Filter **Nearest**, mipmaps off, lossless, no auto-trim.
- Audio: short one-shots `.wav` (mono, no loop); music/ambience `.ogg` (loop, stereo). Commit `.import`.
- Base viewport 640×360, integer scaling.

## 5. Layout
Single copy under `res://assets/art/…` and `res://assets/audio/…` (organized by family/scene).
`shaders/` and `fonts/` are functional single copies. **No `placeholder/` or `final/` folders.**
