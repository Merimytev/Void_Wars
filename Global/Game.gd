extends Node
signal base_destroyed
signal player_defeated
signal minerals_changed(new_value: int)

@onready var spawn = preload("res://Global/SpawnUnit.tscn")

var Minerals = 0
var Energy = 0
var TimePlayed = 0.0
var selected_player: Dictionary = {}
var killed_count: int = 0

func reset_resources():
	Minerals = 0
	Energy = 0
	TimePlayed = 0.0
	killed_count = 0
	selected_player = {}
	print("Ресурсы и время сброшены")

var minerals_send: int:
	get:
		return Minerals
	set(value):
		Minerals = value
		minerals_changed.emit(value)

# Вызывается сервером — создаёт юнит на клиенте по точному пути родителя
@rpc("authority", "reliable")
func sync_spawn_unit(scene_path: String, parent_rel_path: String, pos: Vector2, o_id: int, unit_name: String) -> void:
	if multiplayer.is_server():
		return
	var scene: PackedScene = load(scene_path)
	if not scene:
		return
	var unit = scene.instantiate()
	unit.name = unit_name
	unit.position = pos
	if "owner_id" in unit:
		unit.owner_id = o_id
	unit.set_multiplayer_authority(o_id)
	var parent: Node = get_tree().get_root().get_node_or_null(parent_rel_path)
	if not parent:
		parent = get_tree().get_root().get_node("World")
	parent.add_child(unit)
	var world := get_tree().get_root().get_node_or_null("World")
	if world and world.has_method("get_units"):
		world.get_units()

@rpc("any_peer", "reliable")
func request_sync_building(
		scene_path: String, parent_rel_path: String,
		pos: Vector2, o_id: int, bld_name: String) -> void:
	if not multiplayer.is_server():
		return
	var scene: PackedScene = load(scene_path)
	if not scene:
		return
	var bld = scene.instantiate()
	bld.name = bld_name
	bld.position = pos
	if "owner_id" in bld:
		bld.owner_id = o_id
	bld.set_multiplayer_authority(o_id)
	var parent := get_tree().get_root().get_node_or_null(parent_rel_path)
	if not parent:
		return
	parent.add_child(bld)

func spawnUnit(building_position: Vector2) -> void:
	var path = get_tree().get_root().get_node("World/UI")
	for child in path.get_children():
		if "spawn_unit" in child.name.to_lower() or "SpawnUnit" in child.name:
			return
	var spawn_window = spawn.instantiate()
	spawn_window.spawn_position = building_position + Vector2(0, 60)
	path.add_child(spawn_window)
