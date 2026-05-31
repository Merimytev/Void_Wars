extends CanvasLayer

signal build_selected(building_type: String)

@export var factory_mineral_cost := 50
@export var factory_energy_cost := 30
@export var turret_mineral_cost := 25
@export var turret_energy_cost := 20

func _ready():
	var mineral_texture = load("res://img/Mineral.png")
	var energy_texture = load("res://img/Energy.png")

	_set_rich_label(
		$PanelContainer/HBoxContainer/FactorySlot/HBoxContainer/RichTextLabel,
		mineral_texture, factory_mineral_cost
	)
	_set_rich_label(
		$PanelContainer/HBoxContainer/FactorySlot/HBoxContainer2/RichTextLabel,
		energy_texture, factory_energy_cost
	)
	_set_rich_label(
		$PanelContainer/HBoxContainer/TurretSlot/HBoxContainer2/RichTextLabel,
		mineral_texture, turret_mineral_cost
	)
	_set_rich_label(
		$PanelContainer/HBoxContainer/TurretSlot/HBoxContainer/RichTextLabel,
		energy_texture, turret_energy_cost
	)

func _set_rich_label(label: RichTextLabel, texture: Texture2D, cost: int) -> void:
	label.bbcode_enabled = true
	label.fit_content = true
	label.custom_minimum_size = Vector2(60, 20)  # ← минимальный размер
	label.add_theme_font_size_override("normal_font_size", 12)
	label.append_text("[img=16x16]" + texture.resource_path + "[/img] " + str(cost))
	
func _on_factory_button_pressed() -> void:
	if Game.Minerals >= factory_mineral_cost and Game.Energy >= factory_energy_cost:
		emit_signal("build_selected", "factory")
		queue_free()
	else:
		_flash_error($PanelContainer/HBoxContainer/FactorySlot)

func _on_turret_button_pressed() -> void:
	if Game.Minerals >= turret_mineral_cost and Game.Energy >= turret_energy_cost:
		emit_signal("build_selected", "turret")
		queue_free()
	else:
		_flash_error($PanelContainer/HBoxContainer/TurretSlot)

func _flash_error(slot: Control) -> void:
	var tween = create_tween()
	tween.tween_property(slot, "modulate", Color.RED, 0.1)
	tween.tween_property(slot, "modulate", Color.WHITE, 0.1)
	tween.tween_property(slot, "modulate", Color.RED, 0.1)
	tween.tween_property(slot, "modulate", Color.WHITE, 0.1)
