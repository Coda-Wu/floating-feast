extends Control
## The Morning Decision screen: shows day + weather, offers Sail / Stay. (§5)

@onready var _day_label: Label = $Center/VBox/DayLabel
@onready var _weather_label: Label = $Center/VBox/WeatherLabel
@onready var _sail_button: Button = $Center/VBox/Buttons/SailButton
@onready var _stay_button: Button = $Center/VBox/Buttons/StayButton

func _ready() -> void:
	_day_label.text = tr("Day %d") % GameState.day
	var weather := Database.get_weather(StringName(GameState.weather_id))
	_weather_label.text = tr("Weather: %s") % (tr(weather.display_name) if weather else "—")
	_sail_button.pressed.connect(GameManager.request_sail)
	_stay_button.pressed.connect(GameManager.request_stay)
