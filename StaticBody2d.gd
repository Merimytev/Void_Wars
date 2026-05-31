extends StaticBody2D

@export var max_health := 500.0
@onready var spawn_point: Node2D = $SpawnPoint

var health := max_health


func _ready():
	health = max_health
	add_to_group("enemies", true)  
func get_spawn_position() -> Vector2:
	return spawn_point.global_position

func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0:
		_die()

func _die() -> void:
	
	Game.base_destroyed.emit()
	queue_free()
