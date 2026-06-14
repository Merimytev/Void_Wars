extends CanvasLayer

func _on_play_button_pressed() -> void:
	Game.reset_resources()
	get_tree().change_scene_to_file("res://World.tscn")

func _on_load_button_pressed() -> void:
	pass # Replace with function body.

func _on_network_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Multiplayer/Scenes/MultiplayerMenu.tscn")
	
func _on_stats_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Stats/PlayersList.tscn")

func _on_settings_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Settings/SettingsMenu.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_about_button_pressed() -> void:
	get_tree().change_scene_to_file("res://About.tscn")
