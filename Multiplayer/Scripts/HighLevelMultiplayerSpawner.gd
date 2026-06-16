extends MultiplayerSpawner

# Стартовые позиции по порядку подключения: хост, клиент 1, клиент 2...
const SPAWN_POSITIONS: Array[Vector2] = [
	Vector2(-1600, 650),
	Vector2(2200, -256),
]

@export var network_player: PackedScene
@export var network_player_client: PackedScene

var _spawn_count := 0

func _ready() -> void:
	# spawn_function вызывается на ОБЕИХ машинах с одними данными —
	# это единственный способ передать position через MultiplayerSpawner
	spawn_function = _spawn_from_data
	multiplayer.peer_connected.connect(spawn_player)
	if multiplayer.is_server():
		spawn_player.call_deferred(multiplayer.get_unique_id())

func _spawn_from_data(data: Dictionary) -> Node:
	var is_host: bool = data["is_host"]
	var scene := network_player if is_host else network_player_client
	var player: Node = scene.instantiate()
	player.name = str(data["id"])
	player.position = data["pos"]
	return player

func spawn_player(id: int) -> void:
	if !multiplayer.is_server(): return

	var is_host_spawn := (id == multiplayer.get_unique_id())
	var spawn_pos := SPAWN_POSITIONS[_spawn_count % SPAWN_POSITIONS.size()]
	_spawn_count += 1

	# spawn() вызывает _spawn_from_data на сервере и всех клиентах с одними данными,
	# затем автоматически добавляет узел в spawn_path
	spawn({"id": id, "is_host": is_host_spawn, "pos": spawn_pos})
