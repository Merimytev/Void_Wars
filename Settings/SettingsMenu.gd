extends CanvasLayer

var _saved_aspect: String
var _saved_resolution: Vector2i
var _saved_fullscreen: bool
var _saved_volume: float

@onready var aspect_option: OptionButton = $Panel/VBoxContainer/AspectRatioOption
@onready var resolution_option: OptionButton = $Panel/VBoxContainer/ResolutionOption
@onready var fullscreen_check: CheckBox = $Panel/VBoxContainer/FullscreenCheck
@onready var volume_slider: HSlider = $Panel/VBoxContainer/VolumeSlider

func _ready() -> void:
	_saved_aspect = Settings.current_aspect
	_saved_resolution = Settings.current_resolution
	_saved_fullscreen = Settings.fullscreen
	_saved_volume = Settings.music_volume

	_populate_aspects()
	_populate_resolutions(Settings.current_aspect)
	fullscreen_check.button_pressed = Settings.fullscreen
	_sync_resolution_selection()
	volume_slider.value = Settings.music_volume
	_set_display_controls_disabled(Settings.fullscreen)

func _populate_aspects() -> void:
	aspect_option.clear()
	for aspect in Settings.ASPECT_RATIOS:
		aspect_option.add_item(aspect)
	var idx = Settings.ASPECT_RATIOS.find(Settings.current_aspect)
	aspect_option.select(maxi(idx, 0))

func _populate_resolutions(aspect: String) -> void:
	resolution_option.clear()
	for r in Settings.get_resolutions_for_aspect(aspect):
		resolution_option.add_item(r["label"])

func _sync_resolution_selection() -> void:
	var resolutions = Settings.get_resolutions_for_aspect(Settings.current_aspect)
	for i in resolutions.size():
		if resolutions[i]["size"] == Settings.current_resolution:
			resolution_option.select(i)
			return
	resolution_option.select(0)

func _set_display_controls_disabled(disabled: bool) -> void:
	aspect_option.disabled = disabled
	resolution_option.disabled = disabled

func _on_aspect_ratio_selected(index: int) -> void:
	Settings.current_aspect = Settings.ASPECT_RATIOS[index]
	_populate_resolutions(Settings.current_aspect)
	var resolutions = Settings.get_resolutions_for_aspect(Settings.current_aspect)
	if not resolutions.is_empty():
		Settings.current_resolution = resolutions[0]["size"]

func _on_resolution_selected(index: int) -> void:
	var resolutions = Settings.get_resolutions_for_aspect(Settings.current_aspect)
	if index < resolutions.size():
		Settings.current_resolution = resolutions[index]["size"]

func _on_fullscreen_toggled(toggled_on: bool) -> void:
	Settings.fullscreen = toggled_on
	_set_display_controls_disabled(toggled_on)

func _on_apply_pressed() -> void:
	Settings.music_volume = volume_slider.value
	Settings.apply_settings()
	Settings.save_settings()
	_saved_aspect = Settings.current_aspect
	_saved_resolution = Settings.current_resolution
	_saved_fullscreen = Settings.fullscreen
	_saved_volume = Settings.music_volume

func _on_back_pressed() -> void:
	Settings.current_aspect = _saved_aspect
	Settings.current_resolution = _saved_resolution
	Settings.fullscreen = _saved_fullscreen
	Settings.music_volume = _saved_volume
	Settings.apply_settings()
	get_tree().change_scene_to_file("res://MainMenu.tscn")
