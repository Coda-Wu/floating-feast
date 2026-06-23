extends Node
## The ONLY place that knows resource file paths. At boot, scans every subfolder of
## res://resources/, loads each .tres, and indexes it by its `id` — failing loudly on
## duplicate ids. Everything else fetches content through here, never by path. (§6, §8)

const RESOURCES_ROOT := "res://resources/"

# id -> Resource indexes.
var _ingredients: Dictionary = {} # id -> IngredientData
var _spirits: Dictionary = {} # id -> SpiritData
var _island_templates: Dictionary = {} # id -> IslandTemplate
var _shop_stocks: Dictionary = {} # id -> ShopStock
var _weather: Dictionary = {} # id -> WeatherData
var _tutorials: Dictionary = {} # id -> TutorialData
var _audio_cues: Dictionary = {} # id -> AudioCue
var _recipes: Dictionary = {} # id -> RecipeData
var _station_recipes: Dictionary = {} # id -> StationRecipe
var _commissions: Dictionary = {} # id -> CommissionData
var _fair_configs: Dictionary = {}
var _world_islands: Dictionary = {} # id -> WorldIslandData

func _ready() -> void:
	# folder name -> the index it fills. Dictionaries are references, so writing
	# through the map mutates the member dict directly.
	var index_map := {
		"ingredients": _ingredients,
		"spirits": _spirits,
		"islands": _island_templates,
		"shops": _shop_stocks,
		"weather": _weather,
		"tutorials": _tutorials,
		"recipes": _recipes,
		"station_recipes": _station_recipes,
		"audio": _audio_cues,
		"commissions": _commissions,
		"fair": _fair_configs,
		"world_islands": _world_islands,
	}
	for folder in index_map:
		_scan_folder(folder, index_map[folder])
	_print_summary()

func _scan_folder(folder: String, into: Dictionary) -> void:
	var path := RESOURCES_ROOT + folder
	if not DirAccess.dir_exists_absolute(path):
		return # legitimately absent until a later milestone (recipes, audio)
	for file in DirAccess.get_files_at(path):
		if not (file.ends_with(".tres") or file.ends_with(".res")):
			continue
		var res: Resource = load(path + "/" + file)
		if res == null:
			push_error("[Database] failed to load %s/%s" % [folder, file])
			continue
		var id_val: Variant = res.get(&"id")
		if not (id_val is StringName or id_val is String) or String(id_val).is_empty():
			push_error("[Database] %s/%s has no usable id" % [folder, file])
			continue
		var id := StringName(id_val)
		if into.has(id):
			push_error("[Database] DUPLICATE id '%s' found in %s (%s)" % [id, folder, file])
			assert(false, "Duplicate resource id: %s" % id) # halts in editor/debug
			continue
		into[id] = res

func _print_summary() -> void:
	print("[Database] indexed: %d ingredients, %d spirits, %d islands, %d shops, %d weather, %d tutorials, %d recipes, %d station_recipes, %d commissions, %d fairs, %d audio, %d world_islands" % [
		_ingredients.size(), _spirits.size(), _island_templates.size(), _shop_stocks.size(),
		_weather.size(), _tutorials.size(), _recipes.size(), _station_recipes.size(), _commissions.size(), _fair_configs.size(), _audio_cues.size(), _world_islands.size()])

# --- Typed accessors (now that the data classes exist) ---
func get_ingredient(id: StringName) -> IngredientData: return _ingredients.get(id)
func get_ingredients_by_source(category: StringName) -> Array[IngredientData]:
	var out: Array[IngredientData] = []
	for ing: IngredientData in _ingredients.values():
		if ing.source_category == category:
			out.append(ing)
	return out

func get_all_ingredients() -> Array[IngredientData]:
	var out: Array[IngredientData] = []
	for ing: IngredientData in _ingredients.values():
		out.append(ing)
	return out

func get_all_recipes() -> Array[RecipeData]:
	var out: Array[RecipeData] = []
	for rec: RecipeData in _recipes.values():
		out.append(rec)
	return out

func get_all_station_recipes() -> Array[StationRecipe]:
	var out: Array[StationRecipe] = []
	for sr: StationRecipe in _station_recipes.values():
		out.append(sr)
	return out

	
func get_spirit(id: StringName) -> SpiritData: return _spirits.get(id)
func get_island_template(id: StringName) -> IslandTemplate: return _island_templates.get(id)
func get_random_island_templates() -> Array[IslandTemplate]:
	var out: Array[IslandTemplate] = []
	for t: IslandTemplate in _island_templates.values():
		if not t.is_mission:
			out.append(t)
	return out
func get_shop_stock(id: StringName) -> ShopStock: return _shop_stocks.get(id)
func get_weather(id: StringName) -> WeatherData: return _weather.get(id)
func get_tutorial(id: StringName) -> TutorialData: return _tutorials.get(id)
func get_audio_cue(id: StringName) -> AudioCue: return _audio_cues.get(id)
func get_recipe(id: StringName) -> RecipeData: return _recipes.get(id)

func get_fair_config(id: StringName) -> FairConfig:
	return _fair_configs.get(id)

func get_commission(id: StringName) -> CommissionData:
	return _commissions.get(id)

func get_all_commissions() -> Array[CommissionData]:
	var out: Array[CommissionData] = []
	for c: CommissionData in _commissions.values():
		out.append(c)
	return out

func get_station_recipe(id: StringName) -> StationRecipe:
	return _station_recipes.get(id)

func get_station_recipes_for(station_id: StringName) -> Array[StationRecipe]:
	var out: Array[StationRecipe] = []
	for sr: StationRecipe in _station_recipes.values():
		if sr.station_id == station_id:
			out.append(sr)
	return out

## Resolve a display name for any item id — ingredient/intermediate, dish, or unknown fallback.
func get_display_name(id: StringName) -> String:
	var ing := get_ingredient(id)
	if ing != null:
		return ing.display_name
	var rec := get_recipe(id)
	if rec != null:
		return rec.display_name
	return String(id).capitalize()

# World islands

func get_world_island(id: StringName) -> WorldIslandData:
	return _world_islands.get(id)

func get_all_world_islands() -> Array[WorldIslandData]:
	var out: Array[WorldIslandData] = []
	for wi: WorldIslandData in _world_islands.values():
		out.append(wi)
	return out