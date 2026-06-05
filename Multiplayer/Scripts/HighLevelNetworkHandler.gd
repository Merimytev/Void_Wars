extends Node

const PORT: int = 42070

var peer: ENetMultiplayerPeer

func start_server() -> Error:
	peer = ENetMultiplayerPeer.new()
	var err: Error = peer.create_server(PORT)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	return OK

func start_client(ip: String) -> Error:
	peer = ENetMultiplayerPeer.new()
	var err: Error = peer.create_client(ip, PORT)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	return OK

func disconnect_peer() -> void:
	if multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.disconnect(_on_peer_disconnected)
	if multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.disconnect(_on_server_disconnected)
	if peer:
		peer.close()
	multiplayer.multiplayer_peer = null

func _on_peer_disconnected(id: int) -> void:
	print("[Network] Peer disconnected: ", id)

func _on_server_disconnected() -> void:
	disconnect_peer()
	get_tree().change_scene_to_file("res://MainMenu.tscn")
