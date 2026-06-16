extends "res://Buildings/SolarPanel.gd"

func _ready() -> void:
	if multiplayer.multiplayer_peer == null:
		owner_id = 2
	elif not multiplayer.is_server():
		owner_id = multiplayer.get_unique_id()
	else:
		var peers := multiplayer.get_peers()
		owner_id = peers[0] if not peers.is_empty() else 2
	super._ready()
