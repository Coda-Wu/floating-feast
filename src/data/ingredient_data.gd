class_name IngredientData extends Resource

@export var id: StringName
@export var display_name: String = ""
@export var icon: Texture2D ## placeholder now, final in Week 3
@export var tags: Array[StringName] = [] ## vegetable, fruit, spice, staple, dairy, grain
@export var base_fullness: int = 0 ## flat raw-feed value for spirit encounters
@export var base_quality: int = 1 ## 1–5, feeds the cooking tier (Week 2)
@export var source_category: StringName ## orchard, shop, butchery, spirit_drop, ...