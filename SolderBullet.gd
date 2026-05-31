extends Area2D

var speed := 300.0
var damage := 10.0
var direction := Vector2.ZERO
var lifetime := 3.0

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
	circle.color = Color(0.362, 0.357, 0.322, 1.0)  # оранжево-красная пуля
	add_child(circle)

func init(dir: Vector2, dmg: float) -> void:
	direction = dir.normalized()
	damage = dmg
	rotation = dir.angle()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	# Бьём только врагов
	if body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
