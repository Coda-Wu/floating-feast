class_name RecipeData extends Resource
## A finished dish: display + family + codex info. The dish's tiered instances live in
## GameState.dish_inventory (keyed recipe_id|tier, Day 11); this is the definition referenced by the
## dish store, commissions, Fair, dish-feeding, and the Recipe Book codex. (§D)

@export var id: StringName # = finished-dish id (== terminal recipe's output_item_id)
@export var display_name: String = ""
@export var icon: Texture2D # placeholder now, final in Week 3
@export var family_tags: Array[StringName] = [] # e.g. [roasted, vegetable] — commission "family" matching
@export var station_id: StringName # the terminal station
@export var codex_path: String = "" # human-readable ingredient + station path (codex display)
@export var terminal_recipe_id: StringName # the StationRecipe that produces it
@export var tier_cap: int = 5 # max reachable tier (simple dishes cap low; the pipeline earns 5)
@export var accepted_flavors: Array[StringName] = [] # spice flavor profiles that improve this dish