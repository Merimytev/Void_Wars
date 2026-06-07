extends MultiplayerSpawner

# Стартовые позиции по порядку подключения: хост, клиент 1, клиент 2...
const SPAWN_POSITIONS: Array[Vector2] = [
	Vector2(-1600, 650),
	Vector2(2200, 300),
]

@export var network_player: PackedScene
@export var network_player_client: PackedScene

var _spawn_count := 0

func _ready() -> void:
	multiplayer.peer_connected.connect(spawn_player)
	if multiplayer.is_server():
		# Откладываем спавн хоста — _ready() вызывается пока дерево занято
		spawn_player.call_deferred(multiplayer.get_unique_id())

func spawn_player(id: int) -> void:
	if !multiplayer.is_server(): return

	var is_host_spawn := (id == multiplayer.get_unique_id())
	var scene := network_player if is_host_spawn else network_player_client

	var player: Node = scene.instantiate()
	player.name = str(id)
	var spawn_pos := SPAWN_POSITIONS[_spawn_count % SPAWN_POSITIONS.size()]
	player.position = spawn_pos
	_spawn_count += 1

	get_node(spawn_path).add_child(player)
