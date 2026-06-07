extends "res://Buildings/Factory.gd"

func _unhandled_input(event: InputEvent) -> void:
	# FactoryClient доступна только клиенту (не хосту/серверу)
	if multiplayer.multiplayer_peer != null and multiplayer.is_server():
		return
	super._unhandled_input(event)
