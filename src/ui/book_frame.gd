class_name BookFrame extends Control
## Shared open-book chrome: parchment body, a spine divider, a top-bookmark row, an optional side-
## bookmark column, two content pages, and a close button. Consumers (Fridge, Recipe Book) instance
## this and populate the exposed containers, so both books look identical. (Parts 1-2)

signal close_requested

@export var background: Texture2D

@onready var _book_panel: PanelContainer = $Center/Book
@onready var _bg_image: TextureRect = $Center/Book/BgImage
@onready var _spine: Panel = $Center/Book/BookMargin/Cols/RightCol/PagesRow/Spine
@onready var _top: HBoxContainer = $Center/Book/BookMargin/Cols/RightCol/TopRow/TopBookmarks
@onready var _side: VBoxContainer = $Center/Book/BookMargin/Cols/SideBookmarks
@onready var _left: MarginContainer = $Center/Book/BookMargin/Cols/RightCol/PagesRow/LeftPage
@onready var _right: MarginContainer = $Center/Book/BookMargin/Cols/RightCol/PagesRow/RightPage
@onready var _close: Button = $Center/Book/BookMargin/Cols/RightCol/TopRow/CloseButton

func _ready() -> void:
	_close.focus_mode = Control.FOCUS_NONE
	_close.pressed.connect(func() -> void: close_requested.emit())
	var spine_sb := StyleBoxFlat.new()
	spine_sb.bg_color = Color(0.42, 0.30, 0.18)
	_spine.add_theme_stylebox_override("panel", spine_sb)
	
	if background != null:
		set_background(background)
	else:
		set_background(null)

func get_top_bookmarks() -> HBoxContainer: return _top
func get_side_bookmarks() -> VBoxContainer: return _side
func get_left_page() -> MarginContainer: return _left
func get_right_page() -> MarginContainer: return _right

func set_background(texture: Texture2D) -> void:
	background = texture
	if _bg_image == null:
		return # guard in case set_background is called before _ready
	if texture != null:
		_bg_image.texture = texture
		_bg_image.visible = true
		_book_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	else:
		_bg_image.visible = false
		_bg_image.texture = null
		var book_sb := StyleBoxFlat.new()
		book_sb.bg_color = Color(0.75, 0.75, 0.75) # silver
		book_sb.set_corner_radius_all(8)
		book_sb.set_border_width_all(5)
		book_sb.border_color = Color(0.54, 0.54, 0.54) # cover
		_book_panel.add_theme_stylebox_override("panel", book_sb)
