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

func spawnUnit(building_position: Vector2) -> void:
	var path = get_tree().get_root().get_node("World/UI")
	for child in path.get_children():
		if "spawn_unit" in child.name.to_lower() or "SpawnUnit" in child.name:
			return
	var spawn_window = spawn.instantiate()
	spawn_window.spawn_position = building_position + Vector2(0, 60)
	path.add_child(spawn_window)
