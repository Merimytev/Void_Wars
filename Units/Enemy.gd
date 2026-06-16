extends CharacterBody2D

@export var hp: int = 100
@export var speed = 100
@export var damage = 20
@export var attack_range = 300.0
@export var detection_range = 300.0
@export var attack_rate = 1.0
@export var preferred_distance = 150.0  # дистанция удержания позиции
@export var max_leash_distance = 200.0
@export var bullet_scene: PackedScene
var max_hp: int = 100
var target = null
var can_attack = true
var hold_position := false  # режим удержания позиции
var start_position := Vector2.ZERO  # позиция где начал держать

@onready var health_bar = $Healthbar

enum State { IDLE, CHASE, HOLD, RETREAT }
var state := State.IDLE

func _ready():
	add_to_group("enemies")
	max_hp = hp
	start_position = global_position

	var timer = Timer.new()
	timer.wait_time = 1.0 / attack_rate
	timer.autostart = false
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_on_attack_timer_timeout"))
	add_child(timer)
	timer.name = "AttackTimer"

func _physics_process(_delta):
	target = find_nearest_unit()

	if not is_instance_valid(target):
		# Нет цели — возвращаемся на позицию удержания
		if hold_position:
			_return_to_position()
		else:
			velocity = Vector2.ZERO
		return

	var dist = global_position.distance_to(target.global_position)
	var dist_to_start = global_position.distance_to(start_position)

	if dist_to_start > max_leash_distance and state != State.RETREAT:
		state = State.IDLE
		_return_to_position()
		return

	match state:
		State.IDLE:
			if dist <= detection_range:
				if hold_position:
					state = State.HOLD
				else:
					state = State.CHASE

		State.CHASE:
			# Преследуем цель
			if dist <= preferred_distance:
				state = State.HOLD
				velocity = Vector2.ZERO
			else:
				_move_toward(target)

		State.HOLD:
			velocity = Vector2.ZERO
			# Атакуем только стоя на месте
			if dist <= attack_range:
				if can_attack:
					attack(target)
					can_attack = false
					$AttackTimer.start()
			elif dist > detection_range:
				# Цель ушла слишком далеко
				if hold_position:
					# Режим удержания — возвращаемся на позицию
					state = State.IDLE
					_return_to_position()
				else:
					state = State.CHASE

		State.RETREAT:
			# Отступаем на стартовую позицию
			
			if dist_to_start < 10.0:
				state = State.IDLE
				velocity = Vector2.ZERO
			else:
				var dir = (start_position - global_position).normalized()
				velocity = dir * speed
				move_and_slide()

func _move_toward(t: Node2D) -> void:
	var dir = (t.global_position - global_position).normalized()
	velocity = dir * speed
	move_and_slide()

func _return_to_position() -> void:
	var dist = global_position.distance_to(start_position)
	if dist > 10.0:
		state = State.RETREAT
	else:
		state = State.IDLE
		velocity = Vector2.ZERO

func find_nearest_unit():
	var units = []
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = detection_range
	query.shape = shape
	query.transform = Transform2D(0, global_position)
	query.collision_mask = 1 << 0
	var results = space_state.intersect_shape(query)
	for result in results:
		var collider = result.collider
		if collider.is_in_group("player_units"):
			units.append(collider)
	units.sort_custom(func(a, b): return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position))
	return units[0] if units else null

func attack(unit):
	if not is_instance_valid(unit):
		return
	if bullet_scene:
		var bullet = bullet_scene.instantiate()
		get_tree().current_scene.add_child(bullet)
		bullet.global_position = global_position
		var dir = (unit.global_position - global_position).normalized()
		if bullet.has_method("init"):
			bullet.init(dir, damage)
		else:
			if unit.has_method("take_damage"):
				unit.take_damage(damage)

func take_damage(dmg):
	hp -= dmg
	update_health_bar()
	if state == State.IDLE:
		state = State.HOLD
	if hp <= 0:
		Game.killed_count += 1
		queue_free()

func _on_attack_timer_timeout():
	can_attack = true

func update_health_bar():
	health_bar.max_value = max_hp
	health_bar.value = hp
	var ratio = float(hp) / float(max_hp)
	if ratio > 0.5:
		health_bar.modulate = Color.GREEN
	elif ratio > 0.25:
		health_bar.modulate = Color.YELLOW
	else:
		health_bar.modulate = Color.RED

# ─── Публичный метод для включения режима удержания ───────────────
func set_hold_position(value: bool) -> void:
	hold_position = value
	start_position = global_position
	if hold_position:
		state = State.HOLD
	else:
		state = State.IDLE
