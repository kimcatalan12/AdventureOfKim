class_name Enemy
extends CharacterBody2D
## Rabbits hop around and bounce off walls. Bats fly over everything and
## drift toward Kim when he comes close.

const RABBIT_SPEED := 90.0
const BAT_SPEED := 72.0
const BAT_SIGHT := 230.0

var kind := "rabbit"
var target: Node2D
var bounds := Rect2()
var frozen := false
var _sprite: Sprite2D
var _direction := Vector2.RIGHT
var _time := 0.0
var _turn_time := 0.0


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1 if kind == "rabbit" else 0
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 12.0
	shape.shape = circle
	add_child(shape)
	_sprite = Sprite2D.new()
	_sprite.offset = Vector2(0, -12)
	add_child(_sprite)
	_time = randf() * 5.0
	_pick_direction()


func _physics_process(delta: float) -> void:
	_time += delta
	_sprite.texture = UI.tex("%s_%d" % [kind, 1 + int(_time * 5.0) % 2])
	if frozen:
		return
	_turn_time -= delta
	if _turn_time <= 0.0:
		_pick_direction()
	if kind == "bat":
		_fly(delta)
	else:
		_hop(delta)


func _hop(delta: float) -> void:
	var hop := 0.55 + 0.45 * absf(sin(_time * 5.0))
	var hit := move_and_collide(_direction * RABBIT_SPEED * hop * delta)
	if hit:
		_direction = _direction.bounce(hit.get_normal()).rotated(randf_range(-0.5, 0.5))
	_sprite.flip_h = _direction.x > 0


func _fly(delta: float) -> void:
	var direction := _direction
	if target and global_position.distance_to(target.global_position) < BAT_SIGHT:
		direction = global_position.direction_to(target.global_position)
	var wobble := Vector2(0, sin(_time * 4.0) * 40.0)
	global_position += (direction * BAT_SPEED + wobble) * delta
	global_position = global_position.clamp(bounds.position, bounds.end)
	if global_position.x <= bounds.position.x or global_position.x >= bounds.end.x:
		_direction.x = -_direction.x
	if global_position.y <= bounds.position.y or global_position.y >= bounds.end.y:
		_direction.y = -_direction.y


func _pick_direction() -> void:
	_direction = Vector2.RIGHT.rotated(randf() * TAU)
	_turn_time = randf_range(1.5, 3.5)
