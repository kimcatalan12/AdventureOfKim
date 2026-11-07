class_name TouchControls
extends Control
## On-screen movement: a virtual joystick or four arrow buttons, chosen in Settings.

const JOY_CENTER := Vector2(110, 430)
const JOY_RADIUS := 72.0
const ARROW_CENTER := Vector2(120, 420)
const ARROW_OFFSET := 56.0
const ARROW_SIZE := 28.0

var _pointer := -1
var _knob := Vector2.ZERO


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _input(event: InputEvent) -> void:
	if Game.touch_style == Game.TouchStyle.HIDDEN or not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		if event.pressed and _pointer == -1 and _inside_area(event.position):
			_pointer = event.index
			_update_vector(event.position)
		elif not event.pressed and event.index == _pointer:
			_release()
	elif event is InputEventScreenDrag and event.index == _pointer:
		_update_vector(event.position)


func _inside_area(point: Vector2) -> bool:
	if Game.touch_style == Game.TouchStyle.JOYSTICK:
		return point.distance_to(JOY_CENTER) <= JOY_RADIUS * 1.5
	return point.distance_to(ARROW_CENTER) <= ARROW_OFFSET * 2.0


func _update_vector(point: Vector2) -> void:
	if Game.touch_style == Game.TouchStyle.JOYSTICK:
		_knob = (point - JOY_CENTER).limit_length(JOY_RADIUS)
		Game.touch_vector = _knob / JOY_RADIUS
	else:
		var offset := point - ARROW_CENTER
		_knob = offset
		if absf(offset.x) > absf(offset.y):
			Game.touch_vector = Vector2(signf(offset.x), 0)
		else:
			Game.touch_vector = Vector2(0, signf(offset.y))
	queue_redraw()


func _release() -> void:
	_pointer = -1
	_knob = Vector2.ZERO
	Game.touch_vector = Vector2.ZERO
	queue_redraw()


func _draw() -> void:
	match Game.touch_style:
		Game.TouchStyle.JOYSTICK:
			draw_circle(JOY_CENTER, JOY_RADIUS, Color(1, 1, 1, 0.22))
			draw_arc(JOY_CENTER, JOY_RADIUS, 0, TAU, 48, Color(1, 1, 1, 0.75), 3.0)
			draw_circle(JOY_CENTER + _knob, 30.0, Color(0.12, 0.71, 0.65, 0.85))
		Game.TouchStyle.ARROWS:
			for direction: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
				_draw_arrow(direction)


func _draw_arrow(direction: Vector2) -> void:
	var center := ARROW_CENTER + direction * ARROW_OFFSET
	var side := direction.orthogonal() * ARROW_SIZE * 0.8
	var active := Game.touch_vector.dot(direction) > 0.5
	var color := Color(0.12, 0.71, 0.65, 0.9) if active else Color(1, 1, 1, 0.55)
	var tip := center + direction * ARROW_SIZE
	var base := center - direction * ARROW_SIZE * 0.6
	draw_colored_polygon(PackedVector2Array([tip, base + side, base - side]), color)
