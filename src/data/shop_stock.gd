class_name ShopStock extends Resource

@export var id: StringName
@export var entries: Array[Dictionary] = []
##   each: { "ingredient_id": StringName, "price": int }