extends Area2D

var speed := 300.0
var damage := 10.0
var direction := Vector2.ZERO
var lifetime := 3.0

func _ready():
	body_entered.connect(_on_body_entered)

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
	if body.is_in_group("player_units"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
