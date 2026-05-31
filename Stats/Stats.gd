extends CanvasLayer

var server_url = "https://void-wars-players-statistics-80327b04.fastapicloud.dev"

@onready var name_label: Label = $Panel/VBoxContainer/NameLabel
@onready var minerals_label: Label = $Panel/VBoxContainer/MineralsLabel
@onready var energy_label: Label = $Panel/VBoxContainer/EnergyLabel
@onready var time_label: Label = $Panel/VBoxContainer/TimeLabel
@onready var killed_label: Label = $Panel/VBoxContainer/KilledLabel

func _ready() -> void:
	if not Game.selected_player.is_empty():
		_fill(Game.selected_player)
		return
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	http_request.request(server_url + "/statistics/")

func _on_request_completed(
		_result: int, response_code: int, _headers: Array, body: PackedByteArray
) -> void:
	if response_code != 200:
		print("HTTP ошибка: ", response_code)
		return
	var json_parser := JSON.new()
	if json_parser.parse(body.get_string_from_utf8()) != OK:
		print("Ошибка парсинга JSON: ", json_parser.error_message)
		return
	var data = json_parser.data
	if typeof(data) != TYPE_ARRAY or data.is_empty():
		return
	var entry = data[data.size() - 1]
	if typeof(entry) != TYPE_DICTIONARY:
		return
	_fill(entry)

func _fill(entry: Dictionary) -> void:
	name_label.text     += " " + str(entry.get("name_input", "—"))
	minerals_label.text += " " + str(int(entry.get("minerals", 0)))
	energy_label.text   += " " + str(int(entry.get("energy", 0)))
	time_label.text     += " " + str(int(entry.get("time_played", 0))) + " сек"
	killed_label.text   += " " + str(int(entry.get("killed", 0))) + " врагов"

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://Stats/PlayersList.tscn")
