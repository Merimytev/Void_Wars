extends Area2D

var speed := 300.0
var damage := 10.0
var direction := Vector2.ZERO
var lifetime := 3.0
var shooter_owner_id: int = 1  # owner_id стреляющего солдата

func _ready():
	body_entered.connect(_on_body_entered)

	# Рисуем круглую пулю через код
	var circle = Polygon2D.new()
	var points = PackedVector2Array()
	var radius = 5.0
	var segments = 16
	for i in range(segments):
		var angle = (2 * PI * i) / segments
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	circle.polygon = points
	circle.color = Color(0.362, 0.357, 0.322, 1.0)
	add_child(circle)

func init(dir: Vector2, dmg: float, attacker_owner_id: int = 1) -> void:
	direction = dir.normalized()
	damage = dmg
	shooter_owner_id = attacker_owner_id
	rotation = dir.angle()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	# Одиночная игра: бьём врагов из группы enemies
	if body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
		return
	# Мультиплеер: бьём узлы противоположной стороны по owner_id
	var target_owner = body.get("owner_id")
	if target_owner == null:
		return
	var is_enemy: bool = (shooter_owner_id == 1 and target_owner != 1) \
		or (shooter_owner_id != 1 and target_owner == 1)
	if is_enemy and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
