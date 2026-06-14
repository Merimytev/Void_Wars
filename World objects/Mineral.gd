extends StaticBody2D

@export var total_minerals := 100
@export var minerals_per_tick := 10
@export var mine_time := 2.0

var current_minerals := total_minerals
# Хранит authority-ID (peer_id) строителей, которые копают
var mining_unit_ids: Array = []

@onready var bar = $ProgressBar
@onready var timer = $Timer

func _ready():
	add_to_group("minerals", true)
	bar.max_value = total_minerals
	bar.value = current_minerals
	timer.wait_time = mine_time
	timer.one_shot = false

func _process(_delta):
	if multiplayer.multiplayer_peer == null or multiplayer.is_server():
		bar.value = current_minerals

# Вызывается строителем когда начинает копать
func start_mining(builder: Node) -> void:
	var peer_id := builder.get_multiplayer_authority()
	if multiplayer.is_server():
		_add_miner(peer_id)
	else:
		_add_miner.rpc_id(1, peer_id)

# Вызывается строителем когда перестаёт копать
func stop_mining(builder: Node) -> void:
	var peer_id := builder.get_multiplayer_authority()
	if multiplayer.is_server():
		_remove_miner(peer_id)
	else:
		_remove_miner.rpc_id(1, peer_id)

@rpc("any_peer", "call_local")
func _add_miner(peer_id: int) -> void:
	if not multiplayer.is_server(): return
	if peer_id not in mining_unit_ids:
		mining_unit_ids.append(peer_id)
	if timer.is_stopped():
		timer.start()

@rpc("any_peer", "call_local")
func _remove_miner(peer_id: int) -> void:
	if not multiplayer.is_server(): return
	mining_unit_ids.erase(peer_id)
	if mining_unit_ids.is_empty():
		timer.stop()

func _on_timer_timeout() -> void:
	if not multiplayer.is_server(): return

	if mining_unit_ids.is_empty():
		timer.stop()
		return

	for peer_id in mining_unit_ids:
		if current_minerals <= 0:
			break
		var amount := mini(minerals_per_tick, current_minerals)
		current_minerals -= amount
		if multiplayer.multiplayer_peer == null or peer_id == 1:
			Game.minerals_send += amount
		else:
			_give_minerals_to_peer.rpc_id(peer_id, amount)

	if current_minerals <= 0:
		_depleted()

@rpc("authority", "reliable")
func _give_minerals_to_peer(amount: int) -> void:
	Game.minerals_send += amount

func _depleted() -> void:
	timer.stop()
	# Уведомляем строителей на сервере что минерал исчерпан
	for builder in get_tree().get_nodes_in_group("builders"):
		if is_instance_valid(builder) and builder.has_method("on_mineral_depleted"):
			if builder.get_multiplayer_authority() in mining_unit_ids:
				builder.on_mineral_depleted()
	_network_despawn.rpc()

# Вызывается на всех пирах — минерал исчезает везде
@rpc("authority", "call_local")
func _network_despawn() -> void:
	queue_free()
