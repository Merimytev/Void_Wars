extends CanvasLayer

@onready var ip_input: LineEdit = $CenterContainer/VBoxContainer/IPInput
@onready var status_label: Label = $CenterContainer/VBoxContainer/StatusLabel
@onready var connect_button: Button = $CenterContainer/VBoxContainer/ConnectButton
@onready var host_button: Button = $CenterContainer/VBoxContainer/HostButton

func _on_host_button_pressed() -> void:
	var err: Error = HighLevelNetworkHandler.start_server()
	if err != OK:
		_show_error("Ошибка запуска сервера: " + error_string(err))
		return
	get_tree().change_scene_to_file("res://Multiplayer/Scenes/MultiplayerWorld.tscn")

func _on_connect_button_pressed() -> void:
	var ip := ip_input.text.strip_edges()
	if ip.is_empty():
		_show_error("Введите IP адрес хоста")
		return

	_show_status("Подключение...")
	connect_button.disabled = true
	host_button.disabled = true

	var err: Error = HighLevelNetworkHandler.start_client(ip)
	if err != OK:
		_show_error("Ошибка: " + error_string(err))
		_reset_buttons()
		return

	if not multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.connect(_on_connected_to_server)
	if not multiplayer.connection_failed.is_connected(_on_connection_failed):
		multiplayer.connection_failed.connect(_on_connection_failed)

func _on_connected_to_server() -> void:
	_disconnect_signals()
	get_tree().change_scene_to_file("res://Multiplayer/Scenes/MultiplayerWorld.tscn")

func _on_connection_failed() -> void:
	_disconnect_signals()
	HighLevelNetworkHandler.disconnect_peer()
	_show_error("Не удалось подключиться. Проверьте IP и порт " + str(HighLevelNetworkHandler.PORT))
	_reset_buttons()

func _disconnect_signals() -> void:
	if multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.disconnect(_on_connected_to_server)
	if multiplayer.connection_failed.is_connected(_on_connection_failed):
		multiplayer.connection_failed.disconnect(_on_connection_failed)

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://MainMenu.tscn")

func _reset_buttons() -> void:
	connect_button.disabled = false
	host_button.disabled = false

func _show_error(msg: String) -> void:
	status_label.add_theme_color_override("font_color", Color(1, 0.35, 0.35, 1))
	status_label.text = msg

func _show_status(msg: String) -> void:
	status_label.add_theme_color_override("font_color", Color(0.55, 0.85, 1, 1))
	status_label.text = msg
