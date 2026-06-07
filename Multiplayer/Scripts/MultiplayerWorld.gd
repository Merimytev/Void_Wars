extends Node2D

var units = []
var total_elapsed_time = 0.0

func _process(delta: float) -> void:
	total_elapsed_time += delta
	update_units()

func _ready():
	Game.reset_resources()
	await get_tree().process_frame
	var win_panel = preload("res://UI/WinPanel.tscn").instantiate()
	add_child(win_panel)
	get_units()

func get_units():
	units = get_tree().get_nodes_in_group("units")

func update_units():
	units = get_tree().get_nodes_in_group("units")
	units = units.filter(func(unit): return is_instance_valid(unit))

func _unhandled_input(event):
	if event.is_action_pressed("RightClick"):
		var mouse_pos = get_global_mouse_position()
		if Input.is_key_pressed(KEY_SHIFT):
			# Shift — добавляем точку в очередь каждому выделенному юниту
			var all_units = get_tree().get_nodes_in_group("units")
			for u in all_units:
				if is_instance_valid(u) and u.get("selected") == true:
					if u.get("target_queue") != null:
						u.target_queue.append(mouse_pos)
						# Если юнит стоит — сразу начинаем движение
						if u.target_queue.size() == 1:
							u._go_to_next_target()
		else:
			_on_right_click(mouse_pos)
# ─── Формирование ─────────────────────────────────────────────────

func _on_right_click(click_position: Vector2) -> void:
	var all_units = get_tree().get_nodes_in_group("units")
	var selected_units = []
	for u in all_units:
		if is_instance_valid(u) and u.get("selected") == true and not u.get("is_constructing"):
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

# ─── Выделение ────────────────────────────────────────────────────

func _on_area_selected(camera_node: Node, additive: bool) -> void:
	var start = camera_node.start
	var end = camera_node.end
	var area = []
	area.append(Vector2(min(start.x, end.x), min(start.y, end.y)))
	area.append(Vector2(max(start.x, end.x), max(start.y, end.y)))
	var ut = get_units_in_area(area)
	if not additive:
		for u in units:
			if u.is_multiplayer_authority():
				u.set_selected(false)
	for u in ut:
		u.set_selected(true)

func _on_single_click(click_position: Vector2):
	var area = []
	area.append(click_position - Vector2(30, 30))
	area.append(click_position + Vector2(30, 50))
	var units_in_click_area = get_units_in_area(area)
	if units_in_click_area.size() == 0:
		for unit in units:
			if unit.is_multiplayer_authority():
				unit.set_selected(false)
	else:
		for unit in units:
			if unit.is_multiplayer_authority():
				unit.set_selected(unit == units_in_click_area[0])

func get_units_in_area(area):
	var u = []
	for unit in units:
		if not unit.is_multiplayer_authority():
			continue
		if unit.position.x > area[0].x and unit.position.x < area[1].x:
			if unit.position.y > area[0].y and unit.position.y < area[1].y:
				u.append(unit)
	return u



func get_elapsed_time() -> float:
	return total_elapsed_time
