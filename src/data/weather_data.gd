class_name WeatherData extends Resource

@export var id: StringName
@export var display_name: String = ""
@export var icon: Texture2D
@export var map_shader: Shader ## null in gray-box
@export var rare_yield_modifiers: Dictionary = {} ## cosmetic for M1; not read yets