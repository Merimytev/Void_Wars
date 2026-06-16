extends CharacterBody2D

const REPAIR_RATE := 20.0
const REPAIR_RANGE := 150.0

@export var selected = false
@export var build_panel_scene: PackedScene
@export var build_preview_scene: PackedScene

var speed = 80
var hp = 60
var max_hp = 60
var owner_id: int = 1  # задаётся в _ready() из имени узла (= peer ID)
var target_queue = []
var is_moving := false
var target_mineral: Node = null
var current_mineral: Node = null
var is_mining := false
var build_panel_instance: Node = null
var repair_mode: bool = false
var repair_target: Node = null
var is_constructing: bool = false

@onready var box = get_node("Box")
@onready var builder_sprite = get_node("Builder")
@onready var navigation_agent = $NavigationAgent2D
@onready var health_bar = $Healthbar

func _enter_tree() -> void:
	var id := name.to_int()
	if id > 0:
		set_multiplayer_authority(id)
	# Если имя не является чистым числом (например "u506808478_12345"),
	# authority уже выставлен фабрикой до add_child — не перетираем.

func _ready():
	var id := name.to_int()
	if id > 0:
		owner_id = id  # спавн через MultiplayerSpawner: имя == peer ID
	set_selected(selected)
	add_to_group("units", true)
	add_to_group("builders", true)
	add_to_group("player_units", true)
	navigation_agent.path_desired_distance = 10.0
	navigation_agent.target_desired_distance = 10.0
	update_health_bar()
	if is_multiplayer_authority():
		var camera := get_viewport().get_camera_2d()
		if camera:
			camera.position = global_position

func _process(delta):
	if is_instance_valid(build_panel_instance):
		var screen_pos = get_viewport().get_canvas_transform() * global_position
		build_panel_instance.get_node("PanelContainer").position = screen_pos + Vector2(-50, -120)

	_check_mining()

	if repair_mode and is_instance_valid(repair_target):
		if global_position.distance_to(repair_target.global_position) <= REPAIR_RANGE:
			_do_repair(delta)

func set_selected(value):
	selected = value
	box.visible = value

func _input(event):
	if is_constructing:
		return
	if not selected:
		return
	if repair_mode:
		if event.is_action_pressed("RightClick"):
			exit_repair_mode()
			return
		if event.is_action_pressed("LeftClick"):
			var building = _get_building_at(get_global_mouse_position())
			if building:
				repair_target = building
				# Идём к точке рядом со зданием, а не в центр (центр внутри коллизии)
				var dir: Vector2 = (global_position - building.global_position).normalized()
				if dir == Vector2.ZERO:
					dir = Vector2.DOWN
				target_queue.clear()
				target_queue.append(building.global_position + dir * 90.0)
				_go_to_next_target()
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("RightClick"):
		var mouse_pos = get_global_mouse_position()
		var mineral = _get_mineral_at(mouse_pos)
		if mineral:
			_go_to_mineral(mineral)
			get_viewport().set_input_as_handled()

func _get_mineral_at(pos: Vector2) -> Node:
	var best: Node = null
	var best_dist := 80.0
	for m in get_tree().get_nodes_in_group("minerals"):
		if not is_instance_valid(m) or not m is Node2D:
			continue
		var d := pos.distance_to((m as Node2D).global_position)
		if d < best_dist:
			best_dist = d
			best = m
	return best

func _go_to_mineral(mineral: Node) -> void:
	_stop_mining()
	target_mineral = mineral
	target_queue.clear()
	target_queue.append(mineral.global_position)
	_go_to_next_target()

func _go_to_next_target() -> void:
	if target_queue.size() == 0:
		is_moving = false
		return
	is_moving = true
	navigation_agent.path_desired_distance = 10.0
	navigation_agent.target_desired_distance = 10.0
	navigation_agent.set_target_position(target_queue[0])

func _physics_process(_delta):
	if !is_multiplayer_authority(): return
	_check_mining()

	if is_moving:
		if navigation_agent.is_navigation_finished():
			is_moving = false
			if is_instance_valid(target_mineral):
				_start_mining(target_mineral)
				target_mineral = null
				navigation_agent.set_target_position(global_position)
				target_queue.clear()
			elif target_queue.size() > 0:
				target_queue.pop_front()
				if target_queue.size() > 0:
					_go_to_next_target()
			return

		var next_path_position = navigation_agent.get_next_path_position()
		var dir = position.direction_to(next_path_position)
		velocity = dir * speed
		move_and_slide()
		if builder_sprite is Sprite2D or builder_sprite is AnimatedSprite2D:
			if velocity.x < 0:
				builder_sprite.flip_h = true
			elif velocity.x > 0:
				builder_sprite.flip_h = false
	else:
		velocity = Vector2.ZERO

func _check_mining() -> void:
	if is_instance_valid(target_mineral):
		var dist = global_position.distance_to(target_mineral.global_position)
		if dist < 60.0:
			_start_mining(target_mineral)
			target_mineral = null
			is_moving = false
			navigation_agent.set_target_position(global_position)
			target_queue.clear()

	if is_mining and is_instance_valid(current_mineral):
		var dist = global_position.distance_to(current_mineral.global_position)
		if dist > 80.0:
			_stop_mining()

func _start_mining(mineral: Node) -> void:
	if not is_instance_valid(mineral):
		return
	current_mineral = mineral
	is_mining = true
	mineral.start_mining(self)

func _stop_mining() -> void:
	if is_instance_valid(current_mineral) and current_mineral.has_method("stop_mining"):
		current_mineral.stop_mining(self)
	current_mineral = null
	is_mining = false

func on_mineral_depleted() -> void:
	current_mineral = null
	is_mining = false

func open_build_panel() -> void:
	if is_constructing:
		return
	if is_instance_valid(build_panel_instance):
		build_panel_instance.queue_free()
		return

	if not build_panel_scene:
		return

	build_panel_instance = build_panel_scene.instantiate()
	get_tree().current_scene.add_child(build_panel_instance)
	build_panel_instance.build_selected.connect(_on_build_selected)
	build_panel_instance.layer = 10

	var panel = build_panel_instance.get_node_or_null("PanelContainer")
	if panel:
		var viewport_size = get_viewport().get_visible_rect().size
		panel.position = viewport_size * 0.5 - panel.size * 0.5
		print("viewport_size: ", viewport_size, " panel.size: ", panel.size)

func _on_build_selected(building_type: String) -> void:
	build_panel_instance = null
	if not build_preview_scene:
		return

	var preview = build_preview_scene.instantiate()
	get_tree().current_scene.add_child(preview)
	preview.setup(building_type, self)

func take_damage(damage):
	hp -= damage
	update_health_bar()
	if hp <= 0:
		_stop_mining()
		queue_free()

func update_health_bar():
	health_bar.max_value = max_hp
	health_bar.value = hp

func request_build(building_type: String) -> void:
	_on_build_selected(building_type)

func enter_repair_mode() -> void:
	repair_mode = true
	repair_target = null

func exit_repair_mode() -> void:
	repair_mode = false
	repair_target = null

func _get_building_at(pos: Vector2) -> Node:
	var space = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collision_mask = 0xFFFFFFFF
	var results = space.intersect_point(query)
	for r in results:
		var col = r["collider"]
		if col.is_in_group("player_units") and col != self and col.get("health") != null:
			return col
	return null

func _do_repair(delta: float) -> void:
	if not is_instance_valid(repair_target):
		repair_target = null
		return
	var health = repair_target.get("health")
	var max_health = repair_target.get("max_health")
	if health != null and max_health != null and health < max_health:
		repair_target.health = minf(health + REPAIR_RATE * delta, max_health)
		var hbar = repair_target.get("health_bar")
		if hbar != null and is_instance_valid(hbar):
			hbar.value = repair_target.health
