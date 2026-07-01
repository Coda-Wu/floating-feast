extends VBoxContainer
## Settings tab — Language (now), Window (B2), Audio (B3). Applies live + persists to settings.cfg. (WP-B)

@onready var _lang_zh: Button = $Language/Row/ZhButton
@onready var _lang_en: Button = $Language/Row/EnButton
@onready var _lang_sys: Button = $Language/Row/SystemButton

@onready var _fullscreen_check: CheckButton = $Window/FullscreenCheck

@onready var _master_slider: HSlider = $Audio/MasterRow/Slider
@onready var _music_slider: HSlider = $Audio/MusicRow/Slider
@onready var _sfx_slider: HSlider = $Audio/SfxRow/Slider


func _ready() -> void:
	for b in [_lang_zh, _lang_en, _lang_sys]:
		b.focus_mode = Control.FOCUS_NONE
	_lang_zh.pressed.connect(func() -> void: LocaleManager.set_language("zh"))
	_lang_en.pressed.connect(func() -> void: LocaleManager.set_language("en"))
	_lang_sys.pressed.connect(func() -> void: LocaleManager.set_language("system"))
	_fullscreen_check.focus_mode = Control.FOCUS_NONE
	_fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)


func _on_fullscreen_toggled(on: bool) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED)
	LocaleManager.save_setting("display", "fullscreen", on)


func _setup_volume(slider: HSlider, bus: String) -> void:
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.focus_mode = Control.FOCUS_NONE
	slider.value = LocaleManager.get_setting("audio", bus, 1.0) # set before connecting → no spurious save
	slider.value_changed.connect(_on_volume_changed.bind(bus))

func _on_volume_changed(value: float, bus: String) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(value))
	LocaleManager.save_setting("audio", bus, value)
