extends CanvasLayer

var _won: bool = false
var server_url = "https://void-wars-players-statistics-80327b04.fastapicloud.dev"

@onready var _dim: ColorRect = $Dim
@onready var _panel: PanelContainer = $Panel
@onready var status_label: Label = $Panel/VBoxContainer/Status
@onready var name_input: TextEdit = $Panel/VBoxContainer/PlayerName

func _ready() -> void:
	_dim.visible = false
	_panel.visible = false
	Game.connect("base_destroyed", Callable(self, "_on_victory"))
	Game.connect("player_defeated", Callable(self, "_on_defeat"))

func _on_victory() -> void:
	if not _won:
		_won = true
		_show_end_screen("Вы победили!")

func _on_defeat() -> void:
	if not _won:
		_won = true
		_show_end_screen("Вы проиграли!")

func _show_end_screen(title_text: String) -> void:
	status_label.text = title_text
	get_tree().paused = true
	_dim.visible = true
	_panel.visible = true

func send_data(
		player_name: String, minerals: int, energy: int, time_played: int, killed: int
) -> void:
	if player_name.strip_edges() == "":
		print("Ошибка: имя пустое")
		return

	var http_request = HTTPRequest.new()
	add_child(http_request)

	var url := "%s/statistics/" % server_url

	var body := JSON.stringify({
		"name_input": player_name,
		"minerals": minerals,
		"energy": energy,
		"time_played": float(time_played),
		"killed": killed
	})

	var headers := ["Content-Type: application/json"]

	print("Отправляем запрос: ", url)
	http_request.request(url, headers, HTTPClient.METHOD_POST, body)
	var result: Array = await http_request.request_completed
	http_request.queue_free()
	_on_request_completed(result[0], result[1], result[2], result[3])
	print("Запрос завершён.")


func _on_request_completed(_result: int, response_code: int, _headers: Array, body: PackedByteArray) -> void:
	print("Response Code: ", response_code)
	if response_code == 201:
		var response = body.get_string_from_utf8()
		print("Response: ", response)
	else:
		print("Ошибка при отправке запроса, статус код: ", response_code)

func _on_stats_pressed() -> void:
	if name_input.text.strip_edges() == "":
		var tween = create_tween()
		tween.tween_property(name_input, "modulate", Color(1.0, 0.3, 0.3), 0.1)
		tween.tween_property(name_input, "modulate", Color(1.0, 1.0, 1.0), 0.3)
		return

	print("Нажата кнопка меню")
	var world_node = get_tree().root.get_node_or_null("World")

	if world_node:
		var time_elapsed = int(world_node.get_elapsed_time())
		print("Время, прошедшее в игре: ", time_elapsed, "секунд")
		await send_data(name_input.text, Game.Minerals, Game.Energy, time_elapsed, Game.killed_count)
		print("Отправлены данные об игре на БД")
	else:
		print("Узел 'World' не найден в дереве сцены.")
		await send_data(name_input.text, Game.Minerals, Game.Energy, 0, Game.killed_count)
		print("Отправлены ПУСТЫЕ данные об игре на БД")

	get_tree().paused = false
	get_tree().change_scene_to_file("res://Stats/Stats.tscn")


func _on_menu_pressed() -> void:
	if name_input.text.strip_edges() == "":
		var tween = create_tween()
		tween.tween_property(name_input, "modulate", Color(1.0, 0.3, 0.3), 0.1)
		tween.tween_property(name_input, "modulate", Color(1.0, 1.0, 1.0), 0.3)
		return

	var world_node = get_tree().root.get_node_or_null("World")

	if world_node:
		var time_elapsed = int(world_node.get_elapsed_time())
		await send_data(name_input.text, Game.Minerals, Game.Energy, time_elapsed, Game.killed_count)
	else:
		await send_data(name_input.text, Game.Minerals, Game.Energy, 0, Game.killed_count)

	get_tree().paused = false
	get_tree().change_scene_to_file("res://MainMenu.tscn")
