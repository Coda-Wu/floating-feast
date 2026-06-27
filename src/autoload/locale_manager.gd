extends Node
## Runtime language handling. Follows the OS language by default, lets the player override it
## (saved to user://settings.cfg), and shows a one-time language picker on first launch.
## UI text auto-translates via Godot's TranslationServer (see res://locale/zh.po). Registered
## as an autoload; it adds NO dependency to existing scenes. Switch live via set_language().

const SETTINGS_PATH := "user://settings.cfg"
const SUPPORTED := ["zh", "en"]

var _popup: CanvasLayer = null

func _ready() -> void:
	var saved := _load_saved()
	if saved == "":
		apply_language("system", false) # default: follow the OS language
		_show_picker()                  # first launch — let the player confirm/choose
	else:
		apply_language(saved, false)
	_make_lang_button() # 常驻"语言"按钮，随时可重新选择语言

## code: "zh" / "en" / "system"
func set_language(code: String) -> void:
	apply_language(code, true)

func apply_language(code: String, save: bool) -> void:
	var locale := _system_language() if code == "system" else code
	if locale not in SUPPORTED:
		locale = "en"
	TranslationServer.set_locale(locale)
	if save:
		_save(code)

func open_language_menu() -> void:
	_show_picker()

# --- a small, always-available "语言" button (own CanvasLayer; touches no game scene) ---
func _make_lang_button() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 127
	var btn := Button.new()
	btn.text = "语言"
	btn.focus_mode = Control.FOCUS_NONE
	btn.modulate = Color(1, 1, 1, 0.78)
	btn.add_theme_font_size_override("font_size", 12)
	layer.add_child(btn)
	btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 4)
	btn.pressed.connect(open_language_menu)
	add_child(layer)

# --- helpers ---
func _system_language() -> String:
	return "zh" if OS.get_locale_language().begins_with("zh") else "en"

func _load_saved() -> String:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return ""
	return str(cfg.get_value("locale", "language", ""))

func _save(code: String) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH) # keep any other settings already saved
	cfg.set_value("locale", "language", code)
	cfg.save(SETTINGS_PATH)

# --- first-launch picker (built in code, so it needs no scene file) ---
func _show_picker() -> void:
	if _popup != null and is_instance_valid(_popup):
		return
	var layer := CanvasLayer.new()
	layer.layer = 128
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)

	var panel := PanelContainer.new()
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "选择语言 / Select Language"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	_add_choice(vbox, "简体中文", "zh", layer)
	_add_choice(vbox, "English", "en", layer)

	add_child(layer)
	_popup = layer

func _add_choice(box: VBoxContainer, label: String, code: String, layer: CanvasLayer) -> void:
	var btn := Button.new()
	btn.text = label
	btn.pressed.connect(func() -> void: _pick(code, layer))
	box.add_child(btn)

func _pick(code: String, layer: CanvasLayer) -> void:
	set_language(code)
	if is_instance_valid(layer):
		layer.queue_free()
	_popup = null
