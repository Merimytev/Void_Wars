extends "res://Buildings/Factory.gd"

# Сцены для подстановки при спавне — клиент всегда создаёт SoldierClient
const SOLDIER_HOST_SCENE = preload("res://Units/Soldier.tscn")
const SOLDIER_CLIENT_SCENE = preload("res://Multiplayer/Scenes/SoldierClient.tscn")
const BUILDER_HOST_SCENE = preload("res://Units/Builder.tscn")

func _ready() -> void:
	super._ready()
	owner_id = _get_client_id()

# Определяет peer ID клиента с учётом контекста (хост видит FactoryClient тоже)
func _get_client_id() -> int:
	if multiplayer.multiplayer_peer == null:
		return 2  # офлайн / одиночная игра
	if not multiplayer.is_server():
		return multiplayer.get_unique_id()
	# Хост видит FactoryClient — берём peer ID первого подключённого клиента
	var peers := multiplayer.get_peers()
	if not peers.is_empty():
		return peers[0]
	# Клиент ещё не подключился — подпишемся и обновим позже
	multiplayer.peer_connected.connect(_on_first_peer_connected, CONNECT_ONE_SHOT)
	return 2  # временное значение до подключения клиента

func _on_first_peer_connected(id: int) -> void:
	owner_id = id

# Перехватывает spawn: если хост передал Soldier.tscn — подменяем на SoldierClient.tscn
# Builder.tscn в мультиплеере не спавним — строитель выдаётся один раз при старте игры
func start_spawn(scene: PackedScene) -> void:
	if scene == SOLDIER_HOST_SCENE:
		super.start_spawn(SOLDIER_CLIENT_SCENE)
	elif scene == BUILDER_HOST_SCENE:
		return
	else:
		super.start_spawn(scene)

func _unhandled_input(event: InputEvent) -> void:
	# FactoryClient доступна только клиенту (не хосту/серверу)
	if multiplayer.multiplayer_peer != null and multiplayer.is_server():
		return
	if event.is_action_pressed("LeftClick"):
		if is_hovered:
			if is_selected:
				is_selected = false
				_close_spawn_menu()
			else:
				_deselect_all_buildings()
				_close_spawn_menu()
				is_selected = true
				Game.spawnUnit(global_position)
