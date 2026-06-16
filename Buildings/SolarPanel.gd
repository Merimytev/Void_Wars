extends StaticBody2D

var POP = preload("res://Global/POP.tscn")

var total_time: int = 50
var curr_time: int = 0
var max_health := 500.0
var health := max_health
var owner_id: int = 1  # 1 = хост; клиентские панели переопределяют в _ready()

@onready var bar = $ProgressBar
@onready var timer = $Timer

func _ready() -> void:
	health = max_health
	add_to_group("player_units", true)
	curr_time = total_time
	bar.max_value = total_time
	timer.start()


func _process(_delta: float) -> void:
	if curr_time <= 10:
		_energy_collected()


func _on_timer_timeout() -> void:
	curr_time -= 1
	var tween = get_tree().create_tween()
	tween.tween_property(bar, "value", curr_time, 0.1).set_trans(Tween.TRANS_LINEAR)

func _energy_collected() -> void:
	var local_is_host: bool = multiplayer.multiplayer_peer == null or multiplayer.is_server()
	var i_own_this: bool = (owner_id == 1) == local_is_host
	if i_own_this:
		Game.Energy += 10
	curr_time = total_time
	bar.max_value = total_time
	bar.value = total_time
	timer.start()
	var pop = POP.instantiate()
	add_child(pop)
	pop.z_index = 1
	pop.show_value(str(10))

func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0:
		if multiplayer.multiplayer_peer != null:
			_destroy_synced.rpc()
		else:
			queue_free()

@rpc("any_peer", "call_local", "reliable")
func _destroy_synced() -> void:
	queue_free()

@rpc("any_peer", "reliable")
func take_damage_authority(amount: float) -> void:
	take_damage(amount)
