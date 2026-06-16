extends Node
## The ONLY place that knows resource file paths. Loads + indexes every .tres
## under res://resources/ at boot, then serves data by id. Bodies filled in Step 2. (§6, §8)

# Typed id -> Resource indexes (populated in Step 2).
var _ingredients: Dictionary = {} # id -> IngredientData
var _spirits: Dictionary = {} # id -> SpiritData
var _island_templates: Dictionary = {} # id -> IslandTemplate
var _shop_stocks: Dictionary = {} # id -> ShopStock
var _weather: Dictionary = {} # id -> WeatherData
var _tutorials: Dictionary = {} # id -> TutorialData
var _audio_cues: Dictionary = {} # id -> AudioCue
var _recipes: Dictionary = {} # id -> RecipeData

func _ready() -> void:
	# Step 2: scan resources/ subfolders, load every .tres, index by id,
	# and fail loudly on duplicate ids.
	pass

func get_ingredient(id: String): return _ingredients.get(id)
func get_spirit(id: String): return _spirits.get(id)
func get_island_template(id: String): return _island_templates.get(id)
func get_shop_stock(id: String): return _shop_stocks.get(id)
func get_weather(id: String): return _weather.get(id)
func get_tutorial(id: String): return _tutorials.get(id)
func get_audio_cue(id: String): return _audio_cues.get(id)
func get_recipe(id: String): return _recipes.get(id)