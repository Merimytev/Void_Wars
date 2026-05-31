extends Node2D

@export var factory_scene: PackedScene
@export var turret_scene: PackedScene
@export var factory_cost_minerals := 50
@export var factory_cost_energy := 30
@export var turret_cost_minerals := 25
@export var turret_cost_energy := 20
@export var build_time := 5.0

var building_type := ""
var can_place := true
var builder_ref: Node = null
var is_placing := false
var build_position := Vector2.ZERO
var pending_scene: PackedScene = null
var pending_mineral_cost := 0
var pending_energy_cost := 0

@onready var sprite = $Sprite2D
@onready var check_area = $CollisionCheck

func _ready():
	sprite.modulate = Color(1, 1, 1, 0.5)

func setup(type: String, builder: Node) -> void:
	building_type = type
	builder_ref = builder

	# Match preview sprite to actual building texture and scale
	var inner: Sprite2D = sprite.get_child(0) as Sprite2D
	if inner:
		match type:
			"factory":
				inner.texture = load("res://img/FactoryBlue.png")
				inner.position = Vector2.ZERO
			"turret":
				inner.texture = load("res://img/SolarPanel.png")
				inner.position = Vector2(0, -15)
	# Both buildings use scale=2 on their root — match that here
	sprite.scale = Vector2(2.0, 2.0)

	# Set collision shape to match building footprint (shape_size × building_scale)
	var cs := check_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs:
		var rect := RectangleShape2D.new()
		match type:
			"factory":
				rect.size = Vector2(60.0, 40.5) * 2.0
			"turret":
				rect.size = Vector2(44.0, 35.0) * 2.0
		cs.shape = rect

func _process(_delta):
	if is_placing:
		return
	global_position = get_global_mouse_position()
	if can_place:
		sprite.modulate = Color(0, 1, 0, 0.5)
	else:
		sprite.modulate = Color(1, 0, 0, 0.5)

func _input(event):
	if is_placing:
		return
	if event.is_action_pressed("LeftClick"):
		if can_place:
			_place_building()
	if event.is_action_pressed("ui_cancel"):
		queue_free()

func _place_building() -> void:
	match building_type:
		"factory":
			pending_scene = factory_scene
			pending_mineral_cost = factory_cost_minerals
			pending_energy_cost = factory_cost_energy
		"turret":
			pending_scene = turret_scene
			pending_mineral_cost = turret_cost_minerals
			pending_energy_cost = turret_cost_energy

	if not pending_scene:
		push_error("BuildPreview: сцена не задана для " + building_type)
		return

	Game.Minerals -= pending_mineral_cost
	Game.Energy -= pending_energy_cost

	build_position = global_position
	is_placing = true
	sprite.visible = false

	if is_instance_valid(builder_ref):
		builder_ref.target_queue.clear()
		builder_ref.target_queue.append(build_position)
		builder_ref._go_to_next_target()
		_wait_for_builder()

func _wait_for_builder() -> void:
	print("ждём строителя к позиции: ", build_position)
	var check_timer = Timer.new()
	check_timer.wait_time = 0.2
	add_child(check_timer)
	check_timer.start()
	check_timer.timeout.connect(func():
		if not is_instance_valid(builder_ref):
			print("строитель не валиден!")
			queue_free()
			return
		var dist = builder_ref.global_position.distance_to(build_position)
		print("дистанция строителя: ", dist)
		if dist < 80.0:
			print("строитель дошёл — начинаем строительство!")
			check_timer.queue_free()
			_start_construction()
	)

func _start_construction() -> void:
	print("_start_construction вызван!")

	var ghost = pending_scene.instantiate()
	var buildings_node = get_tree().get_root().get_node(
		"World/NavigationRegion2D2/NavigationRegion2D/Buildings")
	buildings_node.add_child(ghost)
	ghost.global_position = build_position
	ghost.modulate = Color(1, 1, 1, 0.4)

	var collision = ghost.get_node_or_null("CollisionShape2D")
	if collision:
		collision.disabled = true

	var progress_bar = ProgressBar.new()
	progress_bar.max_value = build_time
	progress_bar.value = 0
	progress_bar.custom_minimum_size = Vector2(60, 10)
	progress_bar.show_percentage = false
	get_tree().get_root().get_node("World/UI").add_child(progress_bar)

	var controller = BuildController.new(ghost, collision, progress_bar, build_time)

	var build_timer = Timer.new()
	build_timer.wait_time = 0.1
	build_timer.one_shot = false
	get_tree().root.add_child(build_timer)
	build_timer.start()

	var captured_builder := builder_ref
	var exit_point := build_position + Vector2(0, 80)

	build_timer.timeout.connect(func():
		print("тик!")
		var done = controller.tick()
		if done:
			build_timer.queue_free()
			print("Здание построено!")
			if is_instance_valid(captured_builder):
				captured_builder.target_queue.clear()
				captured_builder.target_queue.append(exit_point)
				captured_builder._go_to_next_target()
	)

	call_deferred("queue_free")

func _on_collision_check_body_entered(_body):
	can_place = false

func _on_collision_check_body_exited(_body):
	can_place = check_area.get_overlapping_bodies().is_empty()

# ─── Вспомогательный класс для строительства ──────────────────────
class BuildController:
	var ghost: Node
	var collision: Node
	var progress_bar: ProgressBar
	var build_time: float
	var elapsed: float = 0.0

	func _init(g, c, pb, bt):
		ghost = g
		collision = c
		progress_bar = pb
		build_time = bt

	func tick():
		elapsed += 0.1
		if is_instance_valid(progress_bar):
			progress_bar.value = elapsed
		if is_instance_valid(ghost):
			ghost.modulate = Color(1, 1, 1, 0.4 + 0.6 * (elapsed / build_time))
			var screen_pos = ghost.get_viewport().get_canvas_transform() * ghost.global_position
			progress_bar.position = screen_pos + Vector2(-30, -60)
		if elapsed >= build_time:
			if is_instance_valid(ghost):
				ghost.modulate = Color(1, 1, 1, 1.0)
				if is_instance_valid(collision):
					collision.disabled = false
			if is_instance_valid(progress_bar):
				progress_bar.queue_free()
			return true  # готово
		return false
