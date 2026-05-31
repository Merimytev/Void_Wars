extends Node

const CONFIG_PATH = "user://settings.cfg"

const RESOLUTIONS: Array = [
	{"label": "1280×720",  "size": Vector2i(1280, 720),  "aspect": "16:9"},
	{"label": "1366×768",  "size": Vector2i(1366, 768),  "aspect": "16:9"},
	{"label": "1600×900",  "size": Vector2i(1600, 900),  "aspect": "16:9"},
	{"label": "1920×1080", "size": Vector2i(1920, 1080), "aspect": "16:9"},
	{"label": "2560×1440", "size": Vector2i(2560, 1440), "aspect": "16:9"},
	{"label": "3840×2160", "size": Vector2i(3840, 2160), "aspect": "16:9"},
	{"label": "1280×800",  "size": Vector2i(1280, 800),  "aspect": "16:10"},
	{"label": "1440×900",  "size": Vector2i(1440, 900),  "aspect": "16:10"},
	{"label": "1920×1200", "size": Vector2i(1920, 1200), "aspect": "16:10"},
	{"label": "2560×1600", "size": Vector2i(2560, 1600), "aspect": "16:10"},
	{"label": "800×600",   "size": Vector2i(800, 600),   "aspect": "4:3"},
	{"label": "1024×768",  "size": Vector2i(1024, 768),  "aspect": "4:3"},
	{"label": "1280×960",  "size": Vector2i(1280, 960),  "aspect": "4:3"},
	{"label": "1600×1200", "size": Vector2i(1600, 1200), "aspect": "4:3"},
	{"label": "2560×1080", "size": Vector2i(2560, 1080), "aspect": "21:9"},
	{"label": "3440×1440", "size": Vector2i(3440, 1440), "aspect": "21:9"},
	{"label": "1280×1024", "size": Vector2i(1280, 1024), "aspect": "5:4"},
]

const ASPECT_RATIOS: Array = ["16:9", "16:10", "4:3", "21:9", "5:4"]

var fullscreen: bool = true
var current_aspect: String = "16:9"
var current_resolution: Vector2i = Vector2i(1920, 1080)
var music_volume: float = 1.0

func _ready() -> void:
	_load_settings()
	apply_settings()

func get_resolutions_for_aspect(aspect: String) -> Array:
	return RESOLUTIONS.filter(func(r): return r["aspect"] == aspect)

func apply_settings() -> void:
	var window = get_window()
	if fullscreen:
		window.mode = Window.MODE_FULLSCREEN
	else:
		window.mode = Window.MODE_WINDOWED
		window.size = current_resolution
		_center_window()
	var bus := AudioServer.get_bus_index("Music")
	if bus >= 0:
		AudioServer.set_bus_volume_db(bus, linear_to_db(music_volume))

func save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("display", "aspect", current_aspect)
	config.set_value("display", "res_width", current_resolution.x)
	config.set_value("display", "res_height", current_resolution.y)
	config.set_value("audio", "music_volume", music_volume)
	config.save(CONFIG_PATH)

func _load_settings() -> void:
	var config = ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		var screen = DisplayServer.screen_get_size()
		current_aspect = _detect_aspect_ratio(screen)
		current_resolution = _find_closest_resolution(screen, current_aspect)
		fullscreen = true
		return
	fullscreen = config.get_value("display", "fullscreen", true)
	current_aspect = config.get_value("display", "aspect", "16:9")
	var w = config.get_value("display", "res_width", 1920)
	var h = config.get_value("display", "res_height", 1080)
	current_resolution = Vector2i(w, h)
	music_volume = config.get_value("audio", "music_volume", 1.0)

func _center_window() -> void:
	var screen_size = DisplayServer.screen_get_size()
	var win_size = get_window().size
	get_window().position = (screen_size - win_size) / 2

func _detect_aspect_ratio(size: Vector2i) -> String:
	var ratio = float(size.x) / float(size.y)
	if abs(ratio - 16.0 / 9.0) < 0.05:
		return "16:9"
	if abs(ratio - 16.0 / 10.0) < 0.05:
		return "16:10"
	if abs(ratio - 4.0 / 3.0) < 0.05:
		return "4:3"
	if abs(ratio - 21.0 / 9.0) < 0.1:
		return "21:9"
	if abs(ratio - 5.0 / 4.0) < 0.05:
		return "5:4"
	return "16:9"

func _find_closest_resolution(target: Vector2i, aspect: String) -> Vector2i:
	var candidates = get_resolutions_for_aspect(aspect)
	if candidates.is_empty():
		return Vector2i(1920, 1080)
	var best = candidates[0]["size"]
	var best_diff = INF
	for r in candidates:
		var s: Vector2i = r["size"]
		var diff = abs(s.x - target.x) + abs(s.y - target.y)
		if diff < best_diff:
			best_diff = diff
			best = s
	return best
