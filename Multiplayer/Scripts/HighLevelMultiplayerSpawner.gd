extends MultiplayerSpawner

@export var network_player: PackedScene

# Стартовые позиции по порядку подключения: хост, клиент 1, клиент 2...
const SPAWN_POSITIONS: Array[Vector2] = [
	Vector2(-1600, 650),
	Vector2(1900, -400),
]

var _spawn_count := 0

func _ready() -> void:
	multiplayer.peer_connected.connect(spawn_player)
	if multiplayer.is_server():
		spawn_player(multiplayer.get_unique_id())

func spawn_player(id: int) -> void:
	if !multiplayer.is_server(): return

	var player: Node = network_player.instantiate()
	player.name = str(id)
	player.position = SPAWN_POSITIONS[_spawn_count % SPAWN_POSITIONS.size()]
	_spawn_count += 1

	get_node(spawn_path).call_deferred("add_child", player)
