extends SubViewport

class MinimapCanvas extends Node2D:
	var map_scale: float = 0.05
	var vp_size: Vector2 = Vector2(280, 280)
	var world_offset: Vector2 = Vector2.ZERO
	var static_objects: Array = []
	var dynamic_objects: Array = []

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_rect(Rect2(Vector2.ZERO, vp_size), Color(0.08, 0.08, 0.08, 0.9))
		draw_rect(Rect2(Vector2.ZERO, vp_size), Color(0.4, 0.4, 0.4, 1.0), false, 1.5)
		for obj in static_objects:
			var node = obj["node"]
			if not is_instance_valid(node) or node.is_queued_for_deletion():
				continue
			var pos: Vector2 = (node as Node2D).global_position * map_scale + world_offset
			var sz: Vector2 = obj["size"]
			if pos.x < 0 or pos.y < 0 or pos.x > vp_size.x or pos.y > vp_size.y:
				continue
			draw_rect(Rect2(pos - sz * 0.5, sz), obj["color"])
		for obj in dynamic_objects:
			var node = obj["node"]
			if not is_instance_valid(node) or node.is_queued_for_deletion():
				continue
			var pos: Vector2 = (node as Node2D).global_position * map_scale + world_offset
			if pos.x < 0 or pos.y < 0 or pos.x > vp_size.x or pos.y > vp_size.y:
				continue
			draw_circle(pos, obj["radius"], obj["color"])

var canvas: MinimapCanvas

var buildings_container: Node
var trees_container: Node
var minerals_container: Node
var _player_units_count := -1

func _ready() -> void:
	render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var nav := "/root/World/NavigationRegion2D2/NavigationRegion2D"
	buildings_container = get_node_or_null(nav + "/Buildings")
	trees_container     = get_node_or_null(nav + "/Trees")
	minerals_container  = get_node_or_null("/root/World/NavigationRegion2D2/Objects")
	var cam = get_node_or_null("Camera")
	if cam:
		cam.queue_free()

	canvas = MinimapCanvas.new()
	canvas.name = "MinimapCanvas"
	canvas.position = Vector2.ZERO
	canvas.vp_size = Vector2(get_size())
	add_child(canvas)

	if buildings_container:
		buildings_container.child_entered_tree.connect(func(_n): call_deferred("collect_static_objects"))
		buildings_container.child_exiting_tree.connect(func(_n): call_deferred("collect_static_objects"))
	if trees_container:
		trees_container.child_entered_tree.connect(func(_n): call_deferred("collect_static_objects"))
		trees_container.child_exiting_tree.connect(func(_n): call_deferred("collect_static_objects"))
	if minerals_container:
		minerals_container.child_entered_tree.connect(func(_n): call_deferred("collect_static_objects"))
		minerals_container.child_exiting_tree.connect(func(_n): call_deferred("collect_static_objects"))

	await get_tree().process_frame
	canvas.vp_size = Vector2(get_size())
	collect_static_objects()

func collect_static_objects() -> void:
	if not is_inside_tree():
		return
	canvas.static_objects.clear()

	# Здания из группы — работает и в одиночной игре, и в мультиплеере
	for b in get_tree().get_nodes_in_group("player_units"):
		if is_instance_valid(b) and b is Node2D:
			canvas.static_objects.append({"node": b, "color": Color(0.3, 0.5, 1.0), "size": Vector2(9, 9)})
			if not b.tree_exiting.is_connected(_on_object_removed):
				b.tree_exiting.connect(_on_object_removed)

	if trees_container:
		for t in trees_container.get_children():
			if is_instance_valid(t) and t is Node2D:
				canvas.static_objects.append({"node": t, "color": Color(0.2, 0.55, 0.2), "size": Vector2(5, 5)})
				if not t.tree_exiting.is_connected(_on_object_removed):
					t.tree_exiting.connect(_on_object_removed)

	if minerals_container:
		for m in minerals_container.get_children():
			if is_instance_valid(m) and m is Node2D:
				canvas.static_objects.append({"node": m, "color": Color(1.0, 0.85, 0.1), "size": Vector2(6, 6)})
				if not m.tree_exiting.is_connected(_on_object_removed):
					m.tree_exiting.connect(_on_object_removed)

	_recalculate_offset()

func _on_object_removed() -> void:
	canvas.static_objects = canvas.static_objects.filter(func(o): return is_instance_valid(o["node"]))

func _recalculate_offset() -> void:
	if canvas.static_objects.is_empty():
		canvas.world_offset = Vector2.ZERO
		return

	var min_pos := Vector2(INF, INF)
	var max_pos := Vector2(-INF, -INF)
	for obj in canvas.static_objects:
		var p: Vector2 = (obj["node"] as Node2D).global_position
		min_pos = min_pos.min(p)
		max_pos = max_pos.max(p)

	var world_size := max_pos - min_pos
	var padding := 20.0
	var vp := canvas.vp_size
	canvas.map_scale = min(
		(vp.x - padding * 2) / max(world_size.x, 1),
		(vp.y - padding * 2) / max(world_size.y, 1)
	)
	var world_center := (min_pos + max_pos) * 0.5
	canvas.world_offset = vp * 0.5 - world_center * canvas.map_scale

func _process(_delta: float) -> void:
	if not is_inside_tree():
		return
	# Перестраиваем статику при появлении/исчезновении зданий
	var pu_count := get_tree().get_nodes_in_group("player_units").size()
	if pu_count != _player_units_count:
		_player_units_count = pu_count
		collect_static_objects()

	var local_id := 1 if (multiplayer.multiplayer_peer == null or multiplayer.is_server()) \
		else multiplayer.get_unique_id()

	canvas.dynamic_objects.clear()
	for unit in get_tree().get_nodes_in_group("units"):
		if not is_instance_valid(unit) or unit.is_queued_for_deletion():
			continue
		var u_owner = unit.get("owner_id")
		var color := Color(0.3, 0.6, 1.0) if (u_owner == null or u_owner == local_id) \
			else Color(1.0, 0.2, 0.2)
		canvas.dynamic_objects.append({"node": unit, "color": color, "radius": 5.0})
	for unit in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(unit) and unit is Node2D and not unit.is_queued_for_deletion():
			canvas.dynamic_objects.append({"node": unit, "color": Color(1.0, 0.2, 0.2), "radius": 5.0})

	canvas.static_objects = canvas.static_objects.filter(
		func(o): return is_instance_valid(o["node"]))
	canvas.queue_redraw()
