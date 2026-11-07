class_name Player
extends CharacterBody2D

const SPEED := 210.0

var frozen := false
var _sprite: Sprite2D
var _facing := "down"
var _walk_time := 0.0
var _blink_time := 0.0


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(26, 18)
	shape.shape = box
	add_child(shape)
	_sprite = Sprite2D.new()
	_sprite.offset = Vector2(0, -22)
	add_child(_sprite)
	_update_sprite(false)


func _physics_process(delta: float) -> void:
	if frozen:
		velocity = Vector2.ZERO
		_update_sprite(false)
		return
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	input = (input + Game.touch_vector).limit_length(1.0)
	velocity = input * SPEED
	move_and_slide()
	if input.length() > 0.1:
		_walk_time += delta
		if absf(input.x) > absf(input.y):
			_facing = "side"
			_sprite.flip_h = input.x < 0
		else:
			_facing = "down" if input.y > 0 else "up"
			_sprite.flip_h = false
	_update_sprite(input.length() > 0.1)
	if _blink_time > 0.0:
		_blink_time -= delta
		_sprite.visible = fmod(_blink_time, 0.2) > 0.1
	else:
		_sprite.visible = true


func start_blink(seconds: float) -> void:
	_blink_time = seconds


func is_blinking() -> bool:
	return _blink_time > 0.0


func _update_sprite(moving: bool) -> void:
	var frame := 1
	if moving:
		var step := int(_walk_time * 8.0) % 2
		if _facing == "side":
			frame = 1 + step
		else:
			frame = 2 + step
	_sprite.texture = UI.tex("kim_%s_%d" % [_facing, frame])
