extends Node2D

@export var builder_energy: int = 50
@export var soldier_energy: int = 10
@export var soldier_cost: int = 25

var spawn_position := Vector2(300, 300)
var current_building: Node = null

@onready var builder_scene = preload("res://Units/Builder.tscn")
@onready var soldier_scene = preload("res://Units/Soldier.tscn")

func _ready() -> void:
	# Center popup on screen (panel was designed for ~960×512 viewport, center=(480,256))
	var vp := get_viewport().get_visible_rect().size
	position = vp * 0.5 - Vector2(480.0, 256.0)

	var buildings = get_tree().get_root().get_node_or_null(
		"World/NavigationRegion2D2/NavigationRegion2D/Buildings"
	)
	if buildings:
		for building in buildings.get_children():
			if building.get("is_selected") == true:
				current_building = building
				var sp = building.get_node_or_null("SpawnPoint")
				var fallback = building.global_position + Vector2(0, 60)
				spawn_position = sp.global_position if sp else fallback
				break

func _on_create_pressed_builder() -> void:
	if not is_instance_valid(current_building):
		return
	if current_building.get("is_spawning") == true:
		print("Подождите — идёт производство!")
		return
	if Game.Energy < builder_energy:
		print("Недостаточно энергии.")
		return
	Game.Energy -= builder_energy
	current_building.start_spawn(builder_scene)

func _on_create_pressed_soldier() -> void:
	if not is_instance_valid(current_building):
		return
	if current_building.get("is_spawning") == true:
		print("Подождите — идёт производство!")
		return
	if Game.Minerals < soldier_cost:
		print("Недостаточно минералов.")
		return
	if Game.Energy < soldier_energy:
		print("Недостаточно энергии.")
		return
	Game.Minerals -= soldier_cost
	Game.Energy -= soldier_energy
	current_building.start_spawn(soldier_scene)

func _on_close_pressed() -> void:
	var buildings = get_tree().get_root().get_node_or_null(
		"World/NavigationRegion2D2/NavigationRegion2D/Buildings"
	)
	if buildings:
		for building in buildings.get_children():
			if building.get("is_selected") == true:
				building.is_selected = false
	queue_free()
