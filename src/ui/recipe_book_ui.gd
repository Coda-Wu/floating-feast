extends Control
## Recipe Book — knowledge codex of known recipes (name + ingredient→station path). Reads
## GameState.known_recipes fresh on open. Dumb view; emits close_requested. (§C.5)

signal close_requested

@onready var _recipe_list: VBoxContainer = $Center/Panel/Margin/VBox/RecipeScroll/RecipeList
@onready var _close_button: Button = $Center/Panel/Margin/VBox/CloseButton

func setup() -> void:
	_close_button.pressed.connect(func() -> void: close_requested.emit())
	_populate()

func _populate() -> void:
	for c in _recipe_list.get_children():
		c.queue_free()
	if GameState.known_recipes.is_empty():
		var none := Label.new()
		none.text = "No recipes learned yet — cook something to discover one!"
		none.autowrap_mode = TextServer.AUTOWRAP_WORD
		none.custom_minimum_size = Vector2(260, 0)
		_recipe_list.add_child(none)
		return
	for recipe_id in GameState.known_recipes:
		_recipe_list.add_child(_entry(recipe_id))

func _entry(recipe_id: StringName) -> VBoxContainer:
	var rec := Database.get_recipe(recipe_id)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	var name_lbl := Label.new()
	name_lbl.text = rec.display_name if rec else String(recipe_id).capitalize()
	box.add_child(name_lbl)
	var path_lbl := Label.new()
	path_lbl.text = "    " + (rec.codex_path if rec else "")
	path_lbl.modulate = Color(0.72, 0.72, 0.72)
	box.add_child(path_lbl)
	return box