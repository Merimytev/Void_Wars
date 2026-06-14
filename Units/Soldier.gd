extends CharacterBody2D

# ═══ Настройки ═══════════════════════════════════════════════════
@export var selected = false
@export var speed := 100.0
@export var max_hp := 100.0
@export var attack_range := 200.0
@export var fire_rate := 1.0
@export var damage := 25.0
@export var bullet_scene: PackedScene

# ═══ Состояние ═══════════════════════════════════════════════════
var hp := max_hp
var can_shoot := true
var target_queue: Array = []
var is_moving := false
# 1 = хост; клиентские юниты получают peer ID клиента (задаётся фабрикой до _ready)
var owner_id: int = 1

var _sync_timer := 0.0
const _SYNC_INTERVAL := 0.1

# ═══ Узлы ════════════════════════════════════════════════════════
@onready var box = $Box
@onready var health_bar = $Healthbar
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

# ─── Инициализация ────────────────────────────────────────────────

func _ready():
	hp = max_hp
	set_selected(selected)
	add_to_group("units", true)
	add_to_group("player_units", true)

	nav_agent.path_desired_distance = 10.0
	nav_agent.target_desired_distance = 10.0
	nav_agent.avoidance_enabled = false
	nav_agent.navigation_layers = 1  # совпадает со слоем NavigationRegion2D

	var timer = Timer.new()
	timer.name = "ShootTimer"
	timer.wait_time = 1.0 / fire_rate
	timer.one_shot = true
	timer.autostart = false
	timer.timeout.connect(_on_shoot_timer_timeout)
	add_child(timer)

	update_health_bar()

	if multiplayer.multiplayer_peer != null:
		set_multiplayer_authority(owner_id)

# ─── Выделение ────────────────────────────────────────────────────

func set_selected(value: bool) -> void:
	selected = value
	box.visible = value

# ─── Физика ───────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	if multiplayer.multiplayer_peer != null and not is_multiplayer_authority():
		return
	_update_movement()
	move_and_slide()
	_shooting()
	if multiplayer.multiplayer_peer != null:
		_sync_timer += delta
		if _sync_timer >= _SYNC_INTERVAL:
			_sync_timer = 0.0
			_sync_position.rpc(global_position)

@rpc("any_peer", "unreliable")
func _sync_position(pos: Vector2) -> void:
	if not is_multiplayer_authority():
		global_position = pos

func _update_movement() -> void:
	if not is_moving:
		velocity = Vector2.ZERO
		return

	if nav_agent.is_navigation_finished():
		is_moving = false
		target_queue.pop_front()
		if target_queue.size() > 0:
			_go_to_next_target()
		velocity = Vector2.ZERO
		return

	var next_pos = nav_agent.get_next_path_position()
	if next_pos.distance_squared_to(global_position) < 1.0:
		return
	velocity = global_position.direction_to(next_pos) * speed

func _go_to_next_target() -> void:
	if target_queue.size() == 0:
		is_moving = false
		return
	is_moving = true
	nav_agent.set_target_position(target_queue[0])


# ─── Стрельба ─────────────────────────────────────────────────────

func _shooting() -> void:
	if not can_shoot:
		return
	var enemies = _get_enemies_in_range(attack_range)
	if enemies.is_empty():
		return
	_shoot(enemies[0])
	can_shoot = false
	$ShootTimer.start()

func _shoot(target_node: Node2D) -> void:
	if bullet_scene:
		var bullet = bullet_scene.instantiate()
		get_tree().current_scene.add_child(bullet)
		bullet.global_position = global_position
		var dir = (target_node.global_position - global_position).normalized()
		if bullet.has_method("init"):
			bullet.init(dir, damage, owner_id)
		return
	if target_node.has_method("take_damage"):
		target_node.take_damage(damage)

# Возвращает список враждебных узлов в радиусе attack_range,
# отсортированных по возрастанию расстояния.
func _get_enemies_in_range(radius: float) -> Array:
	var candidates: Array = []
	# Одиночная игра: юниты группы "enemies" (Enemy.gd)
	candidates.append_array(get_tree().get_nodes_in_group("enemies"))
	# Мультиплеер: узлы из "player_units" с owner_id противника
	for node in get_tree().get_nodes_in_group("player_units"):
		var target_owner = node.get("owner_id")
		if target_owner != null and _is_enemy(target_owner):
			candidates.append(node)

	var enemies: Array = []
	for node in candidates:
		if not is_instance_valid(node) or node == self:
			continue
		if node is Node2D:
			var dist: float = global_position.distance_to((node as Node2D).global_position)
			if dist <= radius:
				enemies.append(node)
	enemies.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return global_position.distance_squared_to(a.global_position) \
			< global_position.distance_squared_to(b.global_position)
	)
	return enemies

# Возвращает true, если target_owner_id является враждебным по отношению к this.
# Хостовый юнит (owner_id==1) атакует всё с owner_id!=1 и наоборот.
func _is_enemy(target_owner_id: int) -> bool:
	if owner_id == 1:
		return target_owner_id != 1
	return target_owner_id == 1

# ─── Таймер стрельбы ─────────────────────────────────────────────

func _on_shoot_timer_timeout() -> void:
	can_shoot = true

# ─── Урон и смерть ───────────────────────────────────────────────

func take_damage(amount: float) -> void:
	hp -= amount
	update_health_bar()
	if hp <= 0:
		queue_free()

func update_health_bar() -> void:
	health_bar.max_value = max_hp
	health_bar.value = hp
