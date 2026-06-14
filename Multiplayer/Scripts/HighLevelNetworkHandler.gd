extends Node

const PORT: int = 42070

var peer: ENetMultiplayerPeer

func start_server() -> Error:
	_cleanup_peer()

	peer = ENetMultiplayerPeer.new()
	var err: Error = peer.create_server(PORT)
	if err != OK:
		peer = null
		return err
	multiplayer.multiplayer_peer = peer
	if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	return OK

func start_client(ip: String) -> Error:
	_cleanup_peer()

	peer = ENetMultiplayerPeer.new()
	var err: Error = peer.create_client(ip, PORT)
	if err != OK:
		peer = null
		return err
	multiplayer.multiplayer_peer = peer
	if not multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.connect(_on_server_disconnected)
	return OK

func disconnect_peer() -> void:
	_cleanup_peer()

func _cleanup_peer() -> void:
	if multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.disconnect(_on_peer_disconnected)
	if multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.disconnect(_on_server_disconnected)
	if peer:
		peer.close()
		peer = null
	multiplayer.multiplayer_peer = null

func _on_peer_disconnected(id: int) -> void:
	print("[Network] Пир отсоединён: ", id)
	var player = get_tree().get_root().get_node_or_null("World/" + str(id))
	if player:
		player.queue_free()

func _on_server_disconnected() -> void:
	_cleanup_peer()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://MainMenu.tscn")
