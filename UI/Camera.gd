extends Camera2D

const BOTTOM_BAR_HEIGHT := 165

#Camera Control
@export var CAMERA_SPEED = 30.0
@export var ZOOM_SPEED = 20.0
@export var ZOOM_MARGIN = 0.1
@export var ZOOM_MIN = 0.5
@export var ZOOM_MAX = 3.0

var zoomFactor = 1.0
var zoomPos = Vector2()
var zooming = false

var mousePos = Vector2()
var mousePosGlobal = Vector2()
var start = Vector2()
var startV = Vector2()
var end = Vector2()
var endV = Vector2()

var isDragging = false
var is_additive_selection := false
signal area_selected(camera_node: Node, additive: bool)
signal single_click(position)
@onready var box = get_node("../UI/Panel")

func _ready():
	connect("area_selected", Callable(get_parent(), "_on_area_selected"))
	connect("single_click", Callable(get_parent(), "_on_single_click"))

func _is_over_ui() -> bool:
	var mouse_y := get_viewport().get_mouse_position().y
	return mouse_y > get_viewport().get_visible_rect().size.y - BOTTOM_BAR_HEIGHT

func _process(delta):
	
	var inputX = int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
	var inputY = int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))
	
	position.x = lerp(position.x, position.x + inputX * CAMERA_SPEED * zoom.x, CAMERA_SPEED * delta)
	position.y = lerp(position.y, position.y + inputY * CAMERA_SPEED * zoom.y, CAMERA_SPEED * delta)
	
	var vp := get_viewport_rect().size
	var half_w := vp.x * 0.5 / zoom.x
	var half_h := vp.y * 0.5 / zoom.y
	position.x = clamp(position.x, limit_left + half_w, limit_right - half_w)
	position.y = clamp(position.y, limit_top + half_h, limit_bottom - half_h)
	
	zoom.x = lerp(zoom.x, zoom.x * zoomFactor, ZOOM_SPEED * delta)
	zoom.y = lerp(zoom.y, zoom.y * zoomFactor, ZOOM_SPEED * delta)
	
	zoom.x = clamp(zoom.x, ZOOM_MIN, ZOOM_MAX)
	zoom.y = zoom.x 
	
	if not zooming:
		zoomFactor = 1.0
	
	if Input.is_action_just_pressed("LeftClick") and not _is_over_ui():
		start = mousePosGlobal
		startV = mousePos
		isDragging = true
		is_additive_selection = Input.is_action_pressed("Shift")

	if isDragging:
		end = mousePosGlobal
		endV = mousePos
		draw_area()

	if Input.is_action_just_released("LeftClick") and isDragging:
		if startV.distance_to(mousePos) > 20:
			end = mousePosGlobal
			endV = mousePos
			isDragging = false
			draw_area(false)
			emit_signal("area_selected", self, is_additive_selection)
		else:
			end = start
			endV = mousePos
			isDragging = false
			draw_area(false)
			emit_signal("single_click", mousePosGlobal)

func _input(event):
	if abs(zoomPos.x - get_global_mouse_position().x) > ZOOM_MARGIN:
		zoomFactor = 1.0
	if abs(zoomPos.y - get_global_mouse_position().y) > ZOOM_MARGIN:
		zoomFactor = 1.0
	
	if event is InputEventMouseButton:
		if event.is_pressed():
			zooming = true
			if event.is_action("WheelDown"):
				zoomFactor -= 0.01 * ZOOM_SPEED
				zoomPos = get_global_mouse_position()
			if event.is_action("WheelUp"):
				zoomFactor += 0.01 * ZOOM_SPEED
				zoomPos = get_global_mouse_position()
		else:
			zooming = false
			
	if event is InputEventMouse:
		mousePos = event.position
		mousePosGlobal = get_global_mouse_position()

func draw_area(s=true):
	box.size = Vector2(abs(startV.x - endV.x), abs(startV.y - endV.y))
	var pos = Vector2()
	pos.x = min(startV.x, endV.x)	
	pos.y = min(startV.y, endV.y)
	box.position = pos
	box.size *= int(s)
	var MiniMapPath = get_tree().get_root().get_node("World/UI/MiniMap/SubViewportContainer/SubViewport")
	MiniMapPath._ready()
