extends StaticBody2D

@export var max_health := 1000.0
@export var spawn_delay: float = 5.0

var is_hovered := false
var is_selected := false
var health := max_health
var health_bar: ProgressBar = null
var spawn_bar: ProgressBar = null
var is_spawning := false
var elapsed := 0.0
var pending_scene: PackedScene = null
var spawn_position_offset := Vector2(0, 60)

@onready var select = $Selected

func _ready() -> void:
	health = max_health
	add_to_group("player_units", true)
	_create_health_bar()

func _create_health_bar() -> void:
	health_bar = ProgressBar.new()
	health_bar.max_value = max_health
	health_bar.value = health
	health_bar.custom_minimum_size = Vector2(60, 8)
	health_bar.position = Vector2(-30, -40)
	health_bar.show_percentage = false
	health_bar.add_theme_color_override("font_color", Color.GREEN)
	add_child(health_bar)
	health_bar.visible = false

func _process(delta: float) -> void:
	select.visible = is_selected

	if not is_spawning:
		return

	elapsed += delta

	if is_instance_valid(spawn_bar):
		var screen_pos = get_viewport().get_canvas_transform() * global_position
		spawn_bar.position = screen_pos + Vector2(-30, -60)
		spawn_bar.value = elapsed

	if elapsed >= spawn_delay:
		_finish_spawn()

func start_spawn(scene: PackedScene) -> void:
	if is_spawning:
		return
	pending_scene = scene
	is_spawning = true
	elapsed = 0.0

	spawn_bar = ProgressBar.new()
	spawn_bar.max_value = spawn_delay
	spawn_bar.value = 0
	spawn_bar.custom_minimum_size = Vector2(60, 8)
	spawn_bar.show_percentage = false
	spawn_bar.modulate = Color.CYAN
	get_tree().get_root().get_node("World/UI").add_child(spawn_bar)

func _finish_spawn() -> void:
	is_spawning = false
	elapsed = 0.0

	if is_instance_valid(spawn_bar):
		spawn_bar.queue_free()
		spawn_bar = null

	if not pending_scene:
		return

	var unit = pending_scene.instantiate()
	var sp = get_node_or_null("SpawnPoint")
	var pos = sp.global_position if sp else global_position + spawn_position_offset
	var offset = Vector2(randi_range(-30, 30), randi_range(-30, 30))
	unit.position = pos + offset

	var unit_path = get_tree().get_root().get_node("World/Units")
	unit_path.add_child(unit)
	get_tree().get_root().get_node("World").get_units()
	print("Юнит создан!")

func _unhandled_input(event):
	if event.is_action_pressed("LeftClick"):
		if is_hovered:
			if multiplayer.multiplayer_peer != null and !multiplayer.is_server():
				return
			if is_selected:
				is_selected = false
				_close_spawn_menu()
			else:
				_deselect_all_buildings()
				_close_spawn_menu()
				is_selected = true
				Game.spawnUnit(global_position)

func _deselect_all_buildings() -> void:
	for building in get_tree().get_nodes_in_group("player_units"):
		if building != self and building.get("is_selected") == true:
			building.is_selected = false

func _close_spawn_menu() -> void:
	var ui = get_tree().get_root().get_node_or_null("World/UI")
	if not ui:
		return
	for child in ui.get_children():
		if "spawn_unit" in child.name.to_lower() or "SpawnUnit" in child.name:
			child.free()
			return

func _on_factory_building_mouse_entered() -> void:
	is_hovered = true
	if health < max_health:
		health_bar.visible = true

func _on_factory_building_mouse_exited() -> void:
	is_hovered = false
	health_bar.visible = false

func take_damage(amount: float) -> void:
	health -= amount
	health_bar.value = health
	health_bar.visible = true
	var ratio = health / max_health
	if ratio > 0.5:
		health_bar.modulate = Color.GREEN
	elif ratio > 0.25:
		health_bar.modulate = Color.YELLOW
	else:
		health_bar.modulate = Color.RED
	if health <= 0:
		_die()

func _die() -> void:
	Game.player_defeated.emit()
	queue_free()
