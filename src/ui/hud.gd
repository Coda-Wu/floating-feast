extends Control
## Persistent corner HUD: day, weather, node budget, current quest. A passive view —
## it exposes setters and holds no logic. UIManager listens to SignalBus and pushes
## updates in (canonical flow: System -> SignalBus -> UIManager -> UI scene). (§2.6, §6)

@onready var _day_label: Label = $Panel/PMargin/VBox/TopRow/DayLabel
@onready var _weather_label: Label = $Panel/PMargin/VBox/TopRow/WeatherLabel
@onready var _rank_label: Label = $Panel/PMargin/VBox/TopRow/RankLabel
@onready var _budget_label: Label = $Panel/PMargin/VBox/BudgetLabel
@onready var _quest_label: Label = $Panel/PMargin/VBox/QuestLabel
@onready var _coins_label: Label = $Panel/PMargin/VBox/CoinsLabel
@onready var _commission_label: Label = $Panel/PMargin/VBox/CommissionLabel

func set_day(day: int) -> void:
	_day_label.text = "Day %d" % day

func set_weather(weather_name: String) -> void:
	_weather_label.text = weather_name

func set_rank(rank: int) -> void:
	_rank_label.text = "Rank %d" % rank
	_rank_label.visible = rank > 0


func set_budget(current: int, maximum: int) -> void:
	_budget_label.text = "Time: %d/%d" % [current, maximum]

func set_quest(text: String) -> void:
	_quest_label.text = text

func set_coins(amount: int) -> void:
	_coins_label.text = "Coins: %d" % amount


func set_commission(text: String) -> void:
	_commission_label.text = text
	_commission_label.visible = text != ""