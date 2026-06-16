extends CanvasLayer

@onready var minerals_label = $Minerals
@onready var energy_label = $Energy

func _ready() -> void:
	var bottom_bar = load("res://UI/BottomBar.gd").new()
	bottom_bar.name = "BottomBar"
	add_child(bottom_bar)
	# Рендерить ниже всех UI-элементов (миникарта окажется поверх)
	move_child(bottom_bar, 0)

func _process(_delta: float) -> void:
	minerals_label.text = "Минералы:" + str(Game.Minerals)
	energy_label.text = "Энергия:" + str(Game.Energy)

func flash_no_minerals() -> void:
	_flash_label(minerals_label)

func flash_no_energy() -> void:
	_flash_label(energy_label)

func _flash_label(label: Label) -> void:
	var tw := create_tween()
	tw.tween_property(label, "modulate", Color.RED, 0.08)
	tw.tween_property(label, "modulate", Color.WHITE, 0.08)
	tw.tween_property(label, "modulate", Color.RED, 0.08)
	tw.tween_property(label, "modulate", Color.WHITE, 0.08)
	tw.tween_property(label, "modulate", Color.RED, 0.08)
	tw.tween_property(label, "modulate", Color.WHITE, 0.08)

func _on_menu_pressed() -> void:
	print("Игрок вышел из игры без отправки данных")
	get_tree().change_scene_to_file("res://MainMenu.tscn")


func _on_pause_pressed() -> void:
	if (get_tree().paused == false):
		get_tree().paused = true
	else:
		get_tree().paused = false
