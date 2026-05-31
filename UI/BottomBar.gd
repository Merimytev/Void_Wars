extends Control

const BAR_HEIGHT := 224
const BTN_SIZE := Vector2(110, 82)
const GRID_COLS := 4
const FACTORY_COST := {"minerals": 50, "energy": 30, "time": 5.0}
const SOLAR_COST := {"minerals": 25, "energy": 20, "time": 5.0}

var _selected_builder: Node = null
var _prev_selected: Node = null
var _in_build_mode := false
var _tooltip_show_id: int = 0

var _name_label: Label
var _hp_wrap: Control
var _hp_bar: ProgressBar
var _hp_label: Label
var _desc_label: Label
var _status_label: Label
var _action_grid: GridContainer
var _tooltip: PanelContainer
var _tooltip_title: Label
var _tooltip_minerals: Label
var _tooltip_energy: Label
var _tooltip_time: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	offset_top = -BAR_HEIGHT
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_ui()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.055, 0.065, 0.10, 0.97)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var border := ColorRect.new()
	border.color = Color(0.22, 0.38, 0.65, 0.9)
	border.anchor_left = 0.0
	border.anchor_right = 1.0
	border.anchor_top = 0.0
	border.anchor_bottom = 0.0
	border.offset_bottom = 2.0
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(border)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 0)
	add_child(hbox)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(224, 0)
	hbox.add_child(spacer)

	_add_vsep(hbox)

	var info_margin := MarginContainer.new()
	info_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_margin.size_flags_vertical = Control.SIZE_FILL
	info_margin.add_theme_constant_override("margin_left", 18)
	info_margin.add_theme_constant_override("margin_top", 14)
	info_margin.add_theme_constant_override("margin_right", 18)
	info_margin.add_theme_constant_override("margin_bottom", 14)
	hbox.add_child(info_margin)

	var info_vbox := VBoxContainer.new()
	info_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	info_vbox.add_theme_constant_override("separation", 8)
	info_margin.add_child(info_vbox)

	_name_label = Label.new()
	_name_label.text = ""
	_name_label.add_theme_font_size_override("font_size", 45)
	_name_label.add_theme_color_override("font_color", Color(0.55, 0.70, 0.95))
	info_vbox.add_child(_name_label)

	_hp_wrap = Control.new()
	_hp_wrap.custom_minimum_size = Vector2(0, 22)
	_hp_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hp_wrap.visible = false
	info_vbox.add_child(_hp_wrap)

	_hp_bar = ProgressBar.new()
	_hp_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hp_bar.show_percentage = false
	_hp_wrap.add_child(_hp_bar)

	_hp_label = Label.new()
	_hp_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hp_label.add_theme_font_size_override("font_size", 18)
	_hp_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	_hp_label.add_theme_constant_override("outline_size", 5)
	_hp_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	_hp_wrap.add_child(_hp_label)

	_desc_label = Label.new()
	_desc_label.text = ""
	_desc_label.add_theme_font_size_override("font_size", 24)
	_desc_label.add_theme_color_override("font_color", Color(0.55, 0.70, 0.95))
	info_vbox.add_child(_desc_label)

	_status_label = Label.new()
	_status_label.text = ""
	_status_label.add_theme_font_size_override("font_size", 13)
	_status_label.add_theme_color_override("font_color", Color(0.55, 0.88, 0.55))
	info_vbox.add_child(_status_label)

	_add_vsep(hbox)

	var action_margin := MarginContainer.new()
	action_margin.custom_minimum_size = Vector2(GRID_COLS * (BTN_SIZE.x + 6) + 20, 0)
	action_margin.add_theme_constant_override("margin_left", 8)
	action_margin.add_theme_constant_override("margin_top", 10)
	action_margin.add_theme_constant_override("margin_right", 10)
	action_margin.add_theme_constant_override("margin_bottom", 10)
	hbox.add_child(action_margin)

	_action_grid = GridContainer.new()
	_action_grid.columns = GRID_COLS
	_action_grid.add_theme_constant_override("h_separation", 6)
	_action_grid.add_theme_constant_override("v_separation", 6)
	action_margin.add_child(_action_grid)

	_build_tooltip()

func _build_tooltip() -> void:
	_tooltip = PanelContainer.new()
	_tooltip.visible = false
	_tooltip.z_index = 10

	var sbox := StyleBoxFlat.new()
	sbox.bg_color = Color(0.04, 0.05, 0.12, 0.96)
	sbox.set_border_width_all(1)
	sbox.border_color = Color(0.30, 0.50, 0.85, 0.9)
	sbox.set_corner_radius_all(4)
	sbox.set_content_margin_all(8)
	_tooltip.add_theme_stylebox_override("panel", sbox)
	add_child(_tooltip)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	_tooltip.add_child(vbox)

	_tooltip_title = Label.new()
	_tooltip_title.add_theme_font_size_override("font_size", 14)
	_tooltip_title.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	vbox.add_child(_tooltip_title)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var min_row := HBoxContainer.new()
	min_row.add_theme_constant_override("separation", 5)
	vbox.add_child(min_row)
	var min_icon := TextureRect.new()
	min_icon.custom_minimum_size = Vector2(14, 14)
	min_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	min_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	min_icon.texture = load("res://img/Mineral.png")
	min_row.add_child(min_icon)
	_tooltip_minerals = Label.new()
	_tooltip_minerals.add_theme_font_size_override("font_size", 12)
	_tooltip_minerals.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	min_row.add_child(_tooltip_minerals)

	var en_row := HBoxContainer.new()
	en_row.add_theme_constant_override("separation", 5)
	vbox.add_child(en_row)
	var en_icon := TextureRect.new()
	en_icon.custom_minimum_size = Vector2(14, 14)
	en_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	en_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	en_icon.texture = load("res://img/Energy.png")
	en_row.add_child(en_icon)
	_tooltip_energy = Label.new()
	_tooltip_energy.add_theme_font_size_override("font_size", 12)
	_tooltip_energy.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	en_row.add_child(_tooltip_energy)

	_tooltip_time = Label.new()
	_tooltip_time.add_theme_font_size_override("font_size", 12)
	_tooltip_time.add_theme_color_override("font_color", Color(0.7, 0.75, 0.9))
	vbox.add_child(_tooltip_time)

func _add_vsep(parent: HBoxContainer) -> void:
	var sep := VSeparator.new()
	sep.size_flags_vertical = Control.SIZE_FILL
	parent.add_child(sep)

func _process(_delta: float) -> void:
	_poll_selection()
	_tick_status()

func _poll_selection() -> void:
	var found: Node = null
	for unit in get_tree().get_nodes_in_group("player_units"):
		if unit.get("selected") == true and not unit.is_queued_for_deletion():
			found = unit
			break

	if found == _prev_selected:
		return

	if is_instance_valid(_prev_selected) \
			and _prev_selected.tree_exiting.is_connected(_on_selected_unit_died):
		_prev_selected.tree_exiting.disconnect(_on_selected_unit_died)

	_prev_selected = found
	_selected_builder = found
	_in_build_mode = false
	_hide_tooltip()
	if is_instance_valid(found) and found.get("repair_mode") != null:
		found.set("repair_mode", false)
	if is_instance_valid(found):
		found.tree_exiting.connect(_on_selected_unit_died)
	_refresh()

func _on_selected_unit_died() -> void:
	_prev_selected = null
	_selected_builder = null
	_in_build_mode = false
	_hide_tooltip()
	_refresh()

func _tick_status() -> void:
	if not is_instance_valid(_selected_builder) or _hp_wrap == null:
		return
	var hp = _selected_builder.get("hp")
	var max_hp = _selected_builder.get("max_hp")
	if hp != null and max_hp != null:
		_hp_bar.max_value = max_hp
		_hp_bar.value = hp
		_hp_wrap.visible = true
		var ratio: float = float(hp) / float(max_hp)
		_hp_bar.modulate = Color(1.0 - ratio, ratio, 0.1)
		_hp_label.text = "%d / %d" % [int(hp), int(max_hp)]
		if ratio > 0.66:
			_hp_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
		elif ratio > 0.33:
			_hp_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
		else:
			_hp_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	if _selected_builder.get("repair_mode") == true:
		_status_label.text = "Режим ремонта  [ПКМ — отмена]"
	elif _in_build_mode:
		_status_label.text = "Выберите здание для постройки"
	else:
		_status_label.text = ""

func _refresh() -> void:
	_hide_tooltip()
	for child in _action_grid.get_children():
		child.queue_free()

	if not is_instance_valid(_selected_builder):
		_name_label.text = ""
		_desc_label.text = ""
		if _hp_wrap:
			_hp_wrap.visible = false
		if _status_label:
			_status_label.text = ""
		return

	if _selected_builder.is_in_group("builders"):
		_name_label.text = "Строитель"
		_desc_label.text = "Добывает ресурсы, строит здания"
		if _in_build_mode:
			var sq := Vector2(150, 150)
			_add_btn("ЗАВОД", "F", _on_factory_pressed, "Завод", FACTORY_COST, sq, 18)
			_add_btn("СОЛНЕЧНАЯ\nПАНЕЛЬ", "T", _on_turret_pressed, "Солнечная панель", SOLAR_COST, sq, 18)
			_add_btn("ОТМЕНА", "Esc", _on_cancel_build, "", {}, sq, 18)
		else:
			_add_btn("СТРОИТЬ", "B", _on_build_pressed, "", {}, BTN_SIZE * 2, 26)
			_add_btn("РЕМОНТ", "R", _on_repair_pressed, "", {}, BTN_SIZE * 2, 26)
	else:
		_name_label.text = "Солдат"
		_desc_label.text = "Базовый пехотный юнит"

func _add_btn(label_text: String, hotkey: String, callback: Callable,
		tip_title: String = "", tip_data: Dictionary = {},
		btn_size: Vector2 = BTN_SIZE, btn_font_size: int = 13) -> void:
	var btn := Button.new()
	btn.custom_minimum_size = btn_size
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var sn := StyleBoxFlat.new()
	sn.bg_color = Color(0.09, 0.12, 0.19, 0.95)
	sn.set_corner_radius_all(4)
	sn.set_border_width_all(1)
	sn.border_color = Color(0.28, 0.42, 0.68, 0.75)
	btn.add_theme_stylebox_override("normal", sn)

	var sh := StyleBoxFlat.new()
	sh.bg_color = Color(0.15, 0.21, 0.36, 0.97)
	sh.set_corner_radius_all(4)
	sh.set_border_width_all(1)
	sh.border_color = Color(0.50, 0.72, 1.0, 1.0)
	btn.add_theme_stylebox_override("hover", sh)

	var sp := StyleBoxFlat.new()
	sp.bg_color = Color(0.06, 0.08, 0.14, 0.97)
	sp.set_corner_radius_all(4)
	sp.set_border_width_all(1)
	sp.border_color = Color(0.30, 0.55, 0.90, 1.0)
	btn.add_theme_stylebox_override("pressed", sp)

	btn.text = label_text + "\n[" + hotkey + "]"
	btn.add_theme_font_size_override("font_size", btn_font_size)
	btn.add_theme_color_override("font_color", Color(0.85, 0.90, 1.0))
	btn.add_theme_color_override("font_color_hover", Color(1.0, 1.0, 1.0))

	btn.pressed.connect(callback)

	if not tip_title.is_empty() and not tip_data.is_empty():
		var t := tip_title
		var d := tip_data.duplicate()
		btn.mouse_entered.connect(func():
			_show_tooltip(t, d.get("minerals", 0), d.get("energy", 0), d.get("time", 0.0), btn))
		btn.mouse_exited.connect(_hide_tooltip)

	_action_grid.add_child(btn)

func _show_tooltip(
		title: String, minerals: int, energy: int, build_time: float, btn: Control) -> void:
	_tooltip_show_id += 1
	var my_id := _tooltip_show_id
	_tooltip_title.text = title
	_tooltip_minerals.text = "Минералы: %d" % minerals
	_tooltip_energy.text = "Энергия: %d" % energy
	_tooltip_time.text = "Время постройки: %.0f с" % build_time
	_tooltip.position = Vector2(-9999.0, -9999.0)
	_tooltip.visible = true

	await get_tree().process_frame
	if not _tooltip.visible or _tooltip_show_id != my_id:
		return

	var btn_rect := btn.get_global_rect()
	var bar_rect := get_global_rect()
	var local_pos := btn_rect.position - bar_rect.position
	var tw := _tooltip.size.x
	var th := _tooltip.size.y
	var bw := bar_rect.size.x
	_tooltip.position = Vector2(clamp(local_pos.x, 0.0, bw - tw), local_pos.y - th - 8.0)

func _hide_tooltip() -> void:
	_tooltip_show_id += 1
	if _tooltip != null:
		_tooltip.visible = false

func _on_build_pressed() -> void:
	_in_build_mode = true
	_refresh()

func _on_repair_pressed() -> void:
	if is_instance_valid(_selected_builder) and _selected_builder.has_method("enter_repair_mode"):
		_selected_builder.enter_repair_mode()

func _on_factory_pressed() -> void:
	_request_build("factory")

func _on_turret_pressed() -> void:
	_request_build("turret")

func _on_cancel_build() -> void:
	_in_build_mode = false
	_refresh()

func _request_build(building_type: String) -> void:
	if is_instance_valid(_selected_builder) and _selected_builder.has_method("request_build"):
		_selected_builder.request_build(building_type)
	_in_build_mode = false
	_refresh()

func _input(event: InputEvent) -> void:
	if not is_instance_valid(_selected_builder):
		return
	if not _selected_builder.is_in_group("builders"):
		return
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if _in_build_mode:
		match event.keycode:
			KEY_F:
				_on_factory_pressed()
				get_viewport().set_input_as_handled()
			KEY_T:
				_on_turret_pressed()
				get_viewport().set_input_as_handled()
			KEY_ESCAPE:
				_on_cancel_build()
				get_viewport().set_input_as_handled()
	else:
		match event.keycode:
			KEY_B:
				_on_build_pressed()
				get_viewport().set_input_as_handled()
			KEY_R:
				_on_repair_pressed()
				get_viewport().set_input_as_handled()
