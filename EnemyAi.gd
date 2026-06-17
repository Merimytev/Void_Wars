extends Node

@export var enemy_unit_scene: PackedScene
@export var enemy_base: Node2D   # ← перетащи EnemyBase сюда в Inspector
@export var player_base: Node2D

@export var wave_interval := 30.0
@export var units_per_wave := 5
@export var units_increase_per_wave := 2

var current_wave := 0
var wave_timer := 0.0
var active_units: Array = []

signal wave_started(wave_number: int, unit_count: int)

func _ready():
	if not enemy_unit_scene:
		push_error("EnemyAI: enemy_unit_scene не задана!")
		return
	if not player_base:
		push_error("EnemyAI: player_base не задан!")
		return
	if not enemy_base:
		push_error("EnemyAI: enemy_base не задан!")
		return

	wave_timer = wave_interval - 18.0
	print("EnemyAI: первая волна через 18 секунд")

func _process(delta: float) -> void:
	wave_timer += delta
	if wave_timer >= wave_interval:
		wave_timer = 0.0
		spawn_wave()

	active_units = active_units.filter(func(u): return is_instance_valid(u))

func spawn_wave() -> void:
	if not is_instance_valid(enemy_base):
		print("EnemyAI: здание уничтожено, волны остановлены")
		return

	current_wave += 1
	var count = units_per_wave + (current_wave - 1) * units_increase_per_wave

	print("Волна %d: спавним %d юнитов" % [current_wave, count])
	emit_signal("wave_started", current_wave, count)

	for i in range(count):
		# Небольшая задержка между юнитами чтобы не спавнились в одной точке
		await get_tree().create_timer(0.3 * i).timeout
		spawn_unit()

func spawn_unit() -> void:
	
	if not is_instance_valid(enemy_base):
		return

	if not is_instance_valid(player_base):
		print("EnemyAI: База игрока уничтожена, спавн прекращен.")
		return

	var unit = enemy_unit_scene.instantiate()
	get_tree().current_scene.add_child(unit)

	# Спавним из здания + случайное смещение
	var offset = Vector2(randf_range(-20, 20), randf_range(-20, 20))
	unit.global_position = enemy_base.get_spawn_position() + offset

	# Ещё раз на всякий случай проверяем перед установкой цели
	if is_instance_valid(player_base) and unit.has_method("set_target"):
		unit.set_target(player_base)

	active_units.append(unit)

func get_wave_info() -> Dictionary:
	return {
		"wave": current_wave,
		"active_units": active_units.size(),
		"next_wave_in": wave_interval - wave_timer
	}
