extends Control
## Persistent corner HUD: day, weather, node budget, current quest. A passive view —
## it exposes setters and holds no logic. UIManager listens to SignalBus and pushes
## updates in (canonical flow: System -> SignalBus -> UIManager -> UI scene). (§2.6, §6)

@onready var _day_label: Label = $Panel/PMargin/VBox/TopRow/DayLabel
@onready var _weather_label: Label = $Panel/PMargin/VBox/TopRow/WeatherLabel
@onready var _rank_label: Label = $Panel/PMargin/VBox/TopRow/RankLabel
@onready var _quest_label: Label = $Panel/PMargin/VBox/QuestLabel
@onready var _coins_label: Label = $Panel/PMargin/VBox/CoinsLabel
@onready var _commission_label: Label = $Panel/PMargin/VBox/CommissionLabel
@onready var _time_label: Label = $Panel/PMargin/VBox/TimeRow/TimeLabel
@onready var _time_bar: ProgressBar = $Panel/PMargin/VBox/TimeRow/TimeBar
@onready var _fuel_label: Label = $Panel/PMargin/VBox/FuelRow/FuelLabel
@onready var _fuel_bar: ProgressBar = $Panel/PMargin/VBox/FuelRow/FuelBar
@onready var _buff_label: Label = $Panel/PMargin/VBox/BuffLabel


func _ready() -> void:
	var fuel_fill := StyleBoxFlat.new() # amber → reads as a fuel/gas gauge (gray-box)
	fuel_fill.bg_color = Color(0.95, 0.65, 0.20)
	fuel_fill.set_corner_radius_all(2)
	_fuel_bar.add_theme_stylebox_override("fill", fuel_fill)
	var time_fill := StyleBoxFlat.new() # cool daytime tint
	time_fill.bg_color = Color(0.45, 0.62, 0.85)
	time_fill.set_corner_radius_all(2)
	_time_bar.add_theme_stylebox_override("fill", time_fill)
	_buff_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))

func set_time(minutes: int) -> void:
	_time_label.text = _format_clock(minutes)
	_time_bar.value = minutes

func set_fuel(current: int, maximum: int) -> void:
	_fuel_bar.max_value = maximum
	_fuel_bar.value = current
	_fuel_label.text = tr("Fuel %d/%d") % [current, maximum]

func _format_clock(minutes: int) -> String:
	var h := int(minutes / 60.0) % 24
	var m := minutes % 60
	var suffix := tr("AM") if h < 12 else tr("PM")
	var h12 := h % 12
	if h12 == 0:
		h12 = 12
	return "%d:%02d %s" % [h12, m, suffix]

func set_day(day: int) -> void:
	_day_label.text = tr("Day %d") % day

func set_weather(weather_name: String) -> void:
	_weather_label.text = tr(weather_name)

func set_rank(rank: int) -> void:
	_rank_label.text = tr("Rank %d") % rank
	_rank_label.visible = rank > 0


func set_quest(text: String) -> void:
	_quest_label.text = text

func set_coins(amount: int) -> void:
	_coins_label.text = tr("Coins: %d") % amount


func set_commission(text: String) -> void:
	_commission_label.text = text
	_commission_label.visible = text != ""

func set_buff(buff: Dictionary) -> void:
	if buff.is_empty():
		_buff_label.visible = false
		_buff_label.text = ""
	else:
		_buff_label.visible = true
		_buff_label.text = "✨ %s" % tr(String(buff.get("label", "Run buff")))