class_name BookFrame extends Control
## Shared open-book chrome: fixed-size body (512×288), spine, top-bookmark row, a reserved side-
## bookmark column, and two fixed-size scrollable content pages. The page ScrollContainers (both axes
## Auto) keep any amount of content from resizing the book. Consumers populate the page VBoxes. (P-4)

signal close_requested

@export var background: Texture2D

@onready var _book_panel: PanelContainer = $Center/Book
@onready var _bg_image: TextureRect = $Center/Book/BgImage
@onready var _spine: Panel = $Center/Book/BookMargin/Cols/RightCol/PagesRow/Spine
@onready var _top: HBoxContainer = $Center/Book/BookMargin/Cols/RightCol/TopRow/TopBookmarks
@onready var _side: VBoxContainer = $Center/Book/BookMargin/Cols/SideBookmarks
@onready var _left_content: VBoxContainer = $Center/Book/BookMargin/Cols/RightCol/PagesRow/LeftPage/LeftContent
@onready var _right_content: VBoxContainer = $Center/Book/BookMargin/Cols/RightCol/PagesRow/RightPage/RightContent
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
func get_left_page() -> VBoxContainer: return _left_content
func get_right_page() -> VBoxContainer: return _right_content

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
