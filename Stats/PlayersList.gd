extends CanvasLayer

const SERVER_URL = "https://void-wars-players-statistics-80327b04.fastapicloud.dev"
const FONT_PATH = "res://img/fonts/Orbit-Regular.ttf"

@onready var player_list: VBoxContainer = $Panel/VBoxContainer/ScrollContainer/PlayerListContainer
@onready var back_btn: Button = $Panel/VBoxContainer/Back

var _loading_label: Label

func _ready() -> void:
	player_list.size_flags_horizontal = Control.SIZE_FILL | Control.SIZE_EXPAND
	var scroll := $Panel/VBoxContainer/ScrollContainer as ScrollContainer
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	player_list.add_theme_constant_override("separation", 8)
	back_btn.pressed.connect(_on_back_pressed)

	_loading_label = Label.new()
	_loading_label.text = "Загрузка данных..."
	_loading_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_loading_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_loading_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	_loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loading_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loading_label.add_theme_font_override("font", load(FONT_PATH))
	_loading_label.add_theme_font_size_override("font_size", 28)
	_loading_label.add_theme_color_override("font_color", Color(0.7, 0.8, 1.0, 0.85))
	_loading_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.1, 0.8))
	_loading_label.add_theme_constant_override("outline_size", 5)
	add_child(_loading_label)

	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_request_completed)
	http.request(SERVER_URL + "/statistics/")

func _on_request_completed(
		_result: int, response_code: int, _headers: Array, body: PackedByteArray
) -> void:
	if is_instance_valid(_loading_label):
		_loading_label.queue_free()
	if response_code != 200:
		print("HTTP ошибка: ", response_code)
		return
	var json_parser := JSON.new()
	if json_parser.parse(body.get_string_from_utf8()) != OK:
		return
	var data = json_parser.data
	print("DATA TYPE: ", typeof(data), " | VALUE: ", data)
	if typeof(data) != TYPE_ARRAY:
		return
	print("ENTRIES COUNT: ", data.size())
	for entry in data:
		if typeof(entry) == TYPE_DICTIONARY:
			_add_player_button(entry)

func _add_player_button(entry: Dictionary) -> void:
	var btn := Button.new()
	btn.text = str(entry.get("name_input", "—"))
	btn.custom_minimum_size = Vector2(0, 64)
	btn.size_flags_horizontal = Control.SIZE_FILL | Control.SIZE_EXPAND
	btn.clip_text = false
	btn.add_theme_font_override("font", load(FONT_PATH))
	btn.add_theme_font_size_override("font_size", 30)
	btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	btn.add_theme_constant_override("outline_size", 4)

	var sn := StyleBoxFlat.new()
	sn.bg_color = Color(0.09, 0.12, 0.20, 0.90)
	sn.set_border_width_all(1)
	sn.border_color = Color(0.28, 0.42, 0.68, 0.80)
	sn.set_corner_radius_all(5)
	sn.content_margin_left = 20.0
	sn.content_margin_right = 20.0
	btn.add_theme_stylebox_override("normal", sn)

	var sh := StyleBoxFlat.new()
	sh.bg_color = Color(0.15, 0.21, 0.36, 0.97)
	sh.set_border_width_all(1)
	sh.border_color = Color(0.50, 0.72, 1.0, 1.0)
	sh.set_corner_radius_all(5)
	sh.content_margin_left = 20.0
	sh.content_margin_right = 20.0
	btn.add_theme_stylebox_override("hover", sh)

	var sp := StyleBoxFlat.new()
	sp.bg_color = Color(0.06, 0.08, 0.14, 0.97)
	sp.set_border_width_all(1)
	sp.border_color = Color(0.30, 0.55, 0.90, 1.0)
	sp.set_corner_radius_all(5)
	sp.content_margin_left = 20.0
	sp.content_margin_right = 20.0
	btn.add_theme_stylebox_override("pressed", sp)

	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	btn.pressed.connect(_on_player_selected.bind(entry))
	player_list.add_child(btn)

func _on_player_selected(entry: Dictionary) -> void:
	Game.selected_player = entry
	get_tree().change_scene_to_file("res://Stats/Stats.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://MainMenu.tscn")
