class_name RecipeData extends Resource

@export var id: StringName
@export var display_name: String = ""
@export var icon: Texture2D
@export var required_tags: Array[StringName] = [] ## e.g. [vegetable, vegetable]
@export var required_ingredients: Array[StringName] = [] ## specific ids, if any
@export var station: StringName ## prep, mix_bowl, oven
@export var output_id: StringName ## the dish item id produced