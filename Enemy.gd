extends CharacterBody2D

# ═══ Настройки ═══════════════════════════════════════════════════
@export var speed := 80.0
@export var max_health := 100.0
@export var attack_damage := 10.0
@export var attack_cooldown := 1.5
@export var aggro_range := 150.0

# Дальняя атака
@export var ranged_attack_range := 200.0   # дистанция открытия огня
@export var melee_attack_range := 50.0     # дистанция ближнего боя
@export var bullet_scene: PackedScene      # ← перетащи EnemyBullet.tscn в Inspector

# ═══ Узлы ════════════════════════════════════════════════════════
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var sprite: Sprite2D = $Enemy
@onready var health_bar: ProgressBar = $Healthbar

# ═══ FSM ═════════════════════════════════════════════════════════
enum State { IDLE, MOVE_TO_BASE, CHASE_UNIT, ATTACK_RANGED, ATTACK_MELEE, DEAD }
var state := State.IDLE

var target_base: Node2D = null
var target_unit: Node2D = null
var attack_timer := 0.0
var health := max_health

var path_update_timer := 0.0
var path_update_interval := 0.3

# ─── Инициализация ────────────────────────────────────────────────

func _ready():
	health = max_health
	add_to_group("enemies", true)
	nav_agent.path_desired_distance = 4.0
	nav_agent.target_desired_distance = 10.0
	nav_agent.velocity_computed.connect(_on_velocity_computed)
	# ← Настраиваем существующий бар
	health_bar.max_value = max_health
	health_bar.value = health
	health_bar.show_percentage = false
	health_bar.modulate = Color.GREEN



func set_target(base: Node2D) -> void:
	target_base = base
	state = State.MOVE_TO_BASE
	_update_nav_target()

# ─── Главный цикл ─────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	attack_timer += delta
	path_update_timer += delta

	match state:
		State.IDLE:
			_state_idle()
		State.MOVE_TO_BASE:
			_state_move()
			_check_aggro()
		State.CHASE_UNIT:
			_state_chase()
		State.ATTACK_RANGED:
			_state_attack_ranged()
		State.ATTACK_MELEE:
			_state_attack_melee()

# ─── IDLE ─────────────────────────────────────────────────────────

func _state_idle() -> void:
	if is_instance_valid(target_base):
		state = State.MOVE_TO_BASE
		_update_nav_target()

# ─── MOVE TO BASE ─────────────────────────────────────────────────

func _state_move() -> void:
	if not is_instance_valid(target_base):
		state = State.IDLE
		return

	if path_update_timer >= path_update_interval:
		path_update_timer = 0.0
		_update_nav_target()

	var dist = global_position.distance_to(target_base.global_position)

	if dist <= melee_attack_range:
		target_unit = target_base
		state = State.ATTACK_MELEE
		return

	if dist <= ranged_attack_range:
		target_unit = target_base
		state = State.ATTACK_RANGED
		return

	_move_along_path()

# ─── CHASE ────────────────────────────────────────────────────────

func _state_chase() -> void:
	if not is_instance_valid(target_unit):
		target_unit = null
		state = State.MOVE_TO_BASE
		_update_nav_target()
		return

	var dist = global_position.distance_to(target_unit.global_position)

	if dist > aggro_range * 1.5:
		target_unit = null
		state = State.MOVE_TO_BASE
		_update_nav_target()
		return

	# Достаточно близко — дальняя атака
	if dist <= ranged_attack_range:
		state = State.ATTACK_RANGED
		return

	if path_update_timer >= path_update_interval:
		path_update_timer = 0.0
		nav_agent.set_target_position(target_unit.global_position)

	_move_along_path()

# ─── ДАЛЬНЯЯ АТАКА — стреляем пулей, стоим на месте ──────────────

func _state_attack_ranged() -> void:
	var current_target = target_unit if is_instance_valid(target_unit) else target_base

	if not is_instance_valid(current_target):
		state = State.MOVE_TO_BASE
		return

	var dist = global_position.distance_to(current_target.global_position)

	# Цель подошла вплотную — переходим в ближний бой
	if dist <= melee_attack_range:
		state = State.ATTACK_MELEE
		return

	# Цель ушла слишком далеко — догоняем
	if dist > ranged_attack_range * 1.2:
		state = State.CHASE_UNIT
		return

	# Стреляем по кулдауну
	if attack_timer >= attack_cooldown:
		attack_timer = 0.0
		_shoot(current_target)

	# Поворачиваем спрайт к цели
	var dir = (current_target.global_position - global_position).normalized()
	if is_instance_valid(sprite) and dir.x != 0:
		sprite.flip_h = dir.x < 0

# ─── БЛИЖНЯЯ АТАКА — мгновенный урон ─────────────────────────────

func _state_attack_melee() -> void:
	var current_target = target_unit if is_instance_valid(target_unit) else target_base

	if not is_instance_valid(current_target):
		state = State.MOVE_TO_BASE
		return

	var dist = global_position.distance_to(current_target.global_position)

	if dist > melee_attack_range * 1.2:
		state = State.ATTACK_RANGED
		return

	if attack_timer >= attack_cooldown:
		attack_timer = 0.0
		if current_target.has_method("take_damage"):
			current_target.take_damage(attack_damage)

# ─── Выстрел пулей ────────────────────────────────────────────────

func _shoot(target: Node2D) -> void:
	if not bullet_scene:
		# Если сцены пули нет — мгновенный урон
		if target.has_method("take_damage"):
			target.take_damage(attack_damage)
		return

	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position

	var dir = (target.global_position - global_position).normalized()
	bullet.init(dir, attack_damage)

# ─── Aggro ────────────────────────────────────────────────────────

func _check_aggro() -> void:
	var units = get_tree().get_nodes_in_group("player_units")
	var closest_dist := aggro_range
	var closest: Node2D = null

	for u in units:
		if not is_instance_valid(u):
			continue
		var dist = global_position.distance_to((u as Node2D).global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = u

	if closest:
		target_unit = closest
		state = State.CHASE_UNIT
		nav_agent.set_target_position(target_unit.global_position)

# ─── Навигация ────────────────────────────────────────────────────

func _update_nav_target() -> void:
	if is_instance_valid(target_base):
		nav_agent.set_target_position(target_base.global_position)

func _move_along_path() -> void:
	if nav_agent.is_navigation_finished():
		return

	var next_pos = nav_agent.get_next_path_position()
	var dir = (next_pos - global_position).normalized()
	var new_velocity = dir * speed

	if is_instance_valid(sprite) and dir.x != 0:
		sprite.flip_h = dir.x < 0

	if nav_agent.avoidance_enabled:
		nav_agent.set_velocity(new_velocity)
	else:
		velocity = new_velocity
		move_and_slide()

func _on_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	move_and_slide()

# ─── Урон и смерть ───────────────────────────────────────────────

func take_damage(amount: float) -> void:
	if state == State.DEAD:
		return
	health -= amount
	if is_instance_valid(health_bar):
		health_bar.value = health
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
	state = State.DEAD
	Game.killed_count += 1
	queue_free()
