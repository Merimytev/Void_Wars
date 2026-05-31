extends Node
signal base_destroyed
signal player_defeated
signal minerals_changed(new_value: int)

@onready var spawn = preload("res://Global/SpawnUnit.tscn")

var Minerals = 0
var Energy = 0
var TimePlayed = 0.0
var units = []
var selected_player: Dictionary = {}
var killed_count: int = 0

func reset_resources():
	Minerals = 0
	Energy = 0
	TimePlayed = 0.0
	killed_count = 0
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

func get_units():
	units = get_tree().get_nodes_in_group("units")

func update_units():
	units = units.filter(func(unit): return is_instance_valid(unit))

func get_elapsed_time() -> float:
	return TimePlayed





func _on_right_click(click_position: Vector2) -> void:
	var all_units = get_tree().get_nodes_in_group("units")
	var selected_units = []
	for u in all_units:
		if is_instance_valid(u) and u.get("selected") == true:
			selected_units.append(u)

	if selected_units.is_empty():
		return

	var positions = _get_formation_positions(click_position, selected_units.size())
	for i in range(selected_units.size()):
		var unit = selected_units[i]
		if unit.get("target_queue") != null:
			unit.target_queue.clear()
			unit.target_queue.append(positions[i])
			unit._go_to_next_target()

func _get_formation_positions(center: Vector2, count: int) -> Array:
	var positions = []
	var spacing := 40.0

	if count == 1:
		positions.append(center)
		return positions

	var cols = int(ceil(sqrt(count)))
	for i in range(count):
		var row = i / cols
		var col = i % cols
		var offset = Vector2(
			(col - cols * 0.5 + 0.5) * spacing,
			row * spacing
		)
		positions.append(center + offset)

	return positions
