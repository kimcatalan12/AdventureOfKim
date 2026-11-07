extends Screen
## One playable stage: the map, the collecting, the quiz and the pop-ups.

const TILE := 48
const PICKUP_DISTANCE := 34.0
const HIT_DISTANCE := 30.0
const HIT_SAFE_SECONDS := 1.6
const MIN_SPAWN_TILES := 4

var stage_number: int
var data: Dictionary
var rules: StageRules
var player: Player
var collectibles: Array[Sprite2D] = []
var enemies: Array[Enemy] = []
var questions: Array = []

var _facts: Array = []
var _fact_index := 0
var _world: Node2D
var _free_cells: Array[Vector2i] = []
var _overlay: CanvasLayer
var _overlay_root: Control
var _hud_hearts: Array[TextureRect] = []
var _hud_count: Label
var _hud_goal: Label
var _hud_icon: TextureRect
var _mute_button: Button
var _touch: TouchControls
var _paused := false


func _ready() -> void:
	stage_number = args["stage"]
	data = Game.load_stage(stage_number)
	questions = data["questions"].duplicate()
	questions.shuffle()
	_facts = data["facts"].duplicate()
	_facts.shuffle()
	rules = StageRules.new(_goal_count(), questions.size())
	_build_world()
	_build_hud()
	_spawn_collectibles()
	_spawn_enemies()
	_update_hud()


func _goal_count() -> int:
	var total := 0
	for item: String in data["collect"]:
		total += int(data["collect"][item])
	return total


# ---------- world ----------

func _build_world() -> void:
	var map: Array = data["map"]
	var size := Vector2i(map[0].length(), map.size())
	var area := Rect2(Vector2.ZERO, size * TILE)
	var shade := ColorRect.new()
	shade.color = UI.INK
	shade.position = Vector2(-2000, -2000)
	shade.size = Vector2(6000, 6000)
	add_child(shade)
	var floor_sprite := Sprite2D.new()
	floor_sprite.texture = UI.tex(data["floor"])
	floor_sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	floor_sprite.region_enabled = true
	floor_sprite.region_rect = area
	floor_sprite.centered = false
	add_child(floor_sprite)
	_world = Node2D.new()
	_world.y_sort_enabled = true
	add_child(_world)
	var walls := StaticBody2D.new()
	walls.collision_layer = 1
	_world.add_child(walls)
	var start := Vector2.ZERO
	for y in size.y:
		var row: String = map[y]
		for x in size.x:
			var cell := row[x]
			var center := Vector2(x + 0.5, y + 0.5) * TILE
			match cell:
				"#":
					_add_solid(walls, data["wall"], center)
				"t", "c":
					_add_solid(walls, data["props"][cell], center)
				"P":
					start = center
				_:
					_free_cells.append(Vector2i(x, y))
	player = Player.new()
	player.position = start
	_world.add_child(player)
	var camera := Camera2D.new()
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(area.size.x)
	camera.limit_bottom = int(area.size.y)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	player.add_child(camera)
	camera.make_current()


func _add_solid(walls: StaticBody2D, art: String, center: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = UI.tex(art)
	sprite.position = center
	_world.add_child(sprite)
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(TILE, TILE)
	shape.shape = box
	shape.position = center
	walls.add_child(shape)


func _random_cell(away_from: Vector2, used: Array[Vector2i]) -> Vector2:
	var cells := _free_cells.duplicate()
	cells.shuffle()
	for cell: Vector2i in cells:
		var point := (Vector2(cell) + Vector2(0.5, 0.5)) * TILE
		if point.distance_to(away_from) >= MIN_SPAWN_TILES * TILE and cell not in used:
			used.append(cell)
			return point
	return away_from


func _spawn_collectibles() -> void:
	var used: Array[Vector2i] = []
	for item: String in data["collect"]:
		for i in int(data["collect"][item]):
			_add_collectible(item, _random_cell(player.position, used))


func _add_collectible(item: String, point: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = UI.tex(item)
	sprite.position = point
	sprite.set_meta("item", item)
	_world.add_child(sprite)
	collectibles.append(sprite)
	var bob := sprite.create_tween().set_loops()
	bob.tween_property(sprite, "offset:y", -5.0, 0.5).set_trans(Tween.TRANS_SINE)
	bob.tween_property(sprite, "offset:y", 0.0, 0.5).set_trans(Tween.TRANS_SINE)


func _spawn_enemies() -> void:
	var map: Array = data["map"]
	var bounds := Rect2(Vector2(TILE, TILE), Vector2((map[0].length() - 2) * TILE, (map.size() - 2) * TILE))
	var used: Array[Vector2i] = []
	for kind: String in data["enemies"]:
		for i in int(data["enemies"][kind]):
			var enemy := Enemy.new()
			enemy.kind = kind
			enemy.target = player
			enemy.bounds = bounds
			enemy.position = _random_cell(player.position, used)
			_world.add_child(enemy)
			enemies.append(enemy)


# ---------- each frame ----------

func _process(_delta: float) -> void:
	if _is_frozen():
		return
	for sprite: Sprite2D in collectibles.duplicate():
		if player.position.distance_to(sprite.position) < PICKUP_DISTANCE:
			_pick_up(sprite)
			return
	if player.is_blinking():
		return
	for enemy: Enemy in enemies:
		if player.position.distance_to(enemy.position) < HIT_DISTANCE:
			_on_enemy_hit()
			return


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not rules.phase in [StageRules.Phase.PASSED, StageRules.Phase.FAILED]:
		if _paused:
			_resume()
		elif not _is_frozen():
			pause_game()


func _is_frozen() -> bool:
	return _paused or _overlay_root != null


func _set_frozen(on: bool) -> void:
	player.frozen = on
	for enemy: Enemy in enemies:
		enemy.frozen = on
	if _touch:
		_touch.visible = not on


func _pick_up(sprite: Sprite2D) -> void:
	collectibles.erase(sprite)
	sprite.queue_free()
	Audio.play("pickup")
	var was_seeking := rules.phase == StageRules.Phase.SEEK
	rules.collect()
	_update_hud()
	_show_fact(was_seeking)


func _on_enemy_hit() -> void:
	Audio.play("hit")
	rules.enemy_hit()
	player.start_blink(HIT_SAFE_SECONDS)
	_update_hud()
	if rules.phase == StageRules.Phase.FAILED:
		_show_failed("You ran out of life savers.")


# ---------- pop-ups ----------

func _open_overlay() -> VBoxContainer:
	_close_overlay()
	_overlay_root = Control.new()
	_overlay_root.theme = Game.theme
	_overlay_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(_overlay_root)
	UI.dim(_overlay_root)
	_set_frozen(true)
	return UI.card(_overlay_root, 720)


func _close_overlay() -> void:
	if _overlay_root:
		_overlay_root.queue_free()
		_overlay_root = null
	_set_frozen(false)


func _next_fact() -> String:
	var fact: String = _facts[_fact_index % _facts.size()]
	_fact_index += 1
	return fact


func _show_fact(was_seeking: bool) -> void:
	var box := _open_overlay()
	box.add_child(UI.label("Fact", 28, UI.TEAL_DARK, true))
	box.add_child(UI.label(_next_fact(), 24, UI.INK, true))
	var label := "Back to the question" if was_seeking else "OK"
	if rules.phase == StageRules.Phase.QUIZ and not was_seeking:
		label = "Start the quiz"
	var ok := UI.button(label, _after_fact, Vector2(0, 50))
	box.add_child(ok)
	ok.grab_focus()


func _after_fact() -> void:
	if rules.phase == StageRules.Phase.QUIZ:
		_show_question()
	else:
		_close_overlay()


func _show_question() -> void:
	var box := _open_overlay()
	var header := HBoxContainer.new()
	header.add_child(UI.tag("Question %d of %d" % [rules.question_index + 1, rules.total_questions], 19, UI.MUTED))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	header.add_child(UI.tag("Score: %d" % rules.score, 19, UI.GREEN))
	box.add_child(header)
	box.add_child(QuizQuestion.new(questions[rules.question_index], _on_answer))
	_update_hud()


func _on_answer(correct: bool) -> void:
	Audio.play("correct" if correct else "wrong")
	rules.answer(correct)
	_update_hud()
	match rules.phase:
		StageRules.Phase.PASSED:
			_show_passed()
		StageRules.Phase.FAILED:
			if rules.lives <= 0:
				_show_failed("You used all 3 attempts on one question.")
			else:
				_show_failed("You scored %d out of 20. You need at least %d on the first try." % [rules.score, StageRules.PASS_SCORE])
		StageRules.Phase.SEEK:
			_show_seek()
		_:
			_show_question()


func _show_seek() -> void:
	var item := _review_item()
	var used: Array[Vector2i] = []
	_add_collectible(item, _random_cell(player.position, used))
	var box := _open_overlay()
	box.add_child(UI.label("Not quite!", 30, UI.RED, true))
	box.add_child(UI.label("You lost a life saver. Find the %s on the map to learn a fact, then try again." % item, 22, UI.INK, true))
	var ok := UI.button("OK", _close_overlay, Vector2(0, 50))
	box.add_child(ok)
	ok.grab_focus()


func _review_item() -> String:
	var items: Array = data["collect"].keys()
	return items[randi() % items.size()]


func _show_passed() -> void:
	Audio.play("win")
	Game.record_pass(stage_number, rules.score)
	var box := _open_overlay()
	box.add_child(UI.label("Stage %d clear!" % stage_number, 36, UI.GREEN, true))
	box.add_child(UI.label("You scored %d out of %d." % [rules.score, rules.total_questions], 24, UI.INK, true))
	var next := UI.button("Continue", _continue, Vector2(0, 54))
	box.add_child(next)
	next.grab_focus()


func _continue() -> void:
	if stage_number < Game.STAGE_COUNT:
		Game.go("story", {
			"key": "after%d" % stage_number,
			"next": "lesson",
			"next_args": {"stage": stage_number + 1},
		})
	else:
		Game.go("certificate")


func _show_failed(reason: String) -> void:
	Audio.play("wrong")
	var box := _open_overlay()
	box.add_child(UI.label("Try again!", 34, UI.RED, true))
	box.add_child(UI.label(reason, 22, UI.INK, true))
	var retry := UI.button("Retry stage", _restart, Vector2(0, 52))
	box.add_child(retry)
	box.add_child(UI.button("Exit to menu", func() -> void: Game.go("menu"), Vector2(0, 46)))
	retry.grab_focus()


func _restart() -> void:
	Game.go("stage", {"stage": stage_number})


# ---------- HUD and pause ----------

func _build_hud() -> void:
	var hud := CanvasLayer.new()
	hud.layer = 5
	add_child(hud)
	_touch = TouchControls.new()
	hud.add_child(_touch)
	var bar := HBoxContainer.new()
	bar.theme = Game.theme
	bar.position = Vector2(14, 10)
	bar.size = Vector2(932, 44)
	bar.add_theme_constant_override("separation", 6)
	hud.add_child(bar)
	for i in StageRules.MAX_LIVES:
		var heart := UI.image("heart", Vector2(36, 36))
		bar.add_child(heart)
		_hud_hearts.append(heart)
	var gap := Control.new()
	gap.custom_minimum_size.x = 16
	bar.add_child(gap)
	_hud_icon = UI.image(data["collect"].keys()[0], Vector2(36, 36))
	bar.add_child(_hud_icon)
	_hud_count = _hud_label("")
	bar.add_child(_hud_count)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)
	_hud_goal = _hud_label("")
	bar.add_child(_hud_goal)
	_mute_button = UI.button("", _toggle_mute, Vector2(92, 40))
	_mute_button.focus_mode = Control.FOCUS_NONE
	bar.add_child(_mute_button)
	var pause_button := UI.button("Pause", pause_game, Vector2(92, 40))
	pause_button.focus_mode = Control.FOCUS_NONE
	bar.add_child(pause_button)
	_overlay = CanvasLayer.new()
	_overlay.layer = 10
	add_child(_overlay)


func _hud_label(text: String) -> Label:
	var node := UI.label(text, 21, Color.WHITE)
	node.autowrap_mode = TextServer.AUTOWRAP_OFF
	node.add_theme_color_override("font_outline_color", UI.INK)
	node.add_theme_constant_override("outline_size", 8)
	return node


func _update_hud() -> void:
	for i in _hud_hearts.size():
		_hud_hearts[i].texture = UI.tex("heart" if i < rules.lives else "heart_empty")
	_hud_count.text = "%d / %d" % [mini(rules.collected, rules.goal), rules.goal]
	match rules.phase:
		StageRules.Phase.SEEK:
			_hud_goal.text = "Find the object on the map!"
		StageRules.Phase.COLLECT:
			_hud_goal.text = "Stage %d: %s" % [stage_number, data["name"]]
		_:
			_hud_goal.text = ""
	_mute_button.text = "Sound off" if Game.muted else "Sound on"


func _toggle_mute() -> void:
	Game.muted = not Game.muted
	Audio.apply_settings()
	Game.save_progress()
	_update_hud()


func pause_game() -> void:
	if _is_frozen():
		return
	_paused = true
	_set_frozen(true)
	_show_pause()


var _pause_root: Control


func _show_pause() -> void:
	_pause_root = Control.new()
	_pause_root.theme = Game.theme
	_pause_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(_pause_root)
	UI.dim(_pause_root)
	var box := UI.card(_pause_root, 360)
	box.add_child(UI.label("Paused", 32, UI.INK, true))
	var resume := UI.button("Resume", _resume)
	box.add_child(resume)
	box.add_child(UI.button("Restart", _restart))
	box.add_child(UI.button("Settings", _open_settings))
	box.add_child(UI.button("Exit", func() -> void: Game.go("menu")))
	resume.grab_focus()


func _open_settings() -> void:
	var panel := SettingsPanel.new()
	_pause_root.add_child(panel)


func _resume() -> void:
	_paused = false
	if _pause_root:
		_pause_root.queue_free()
		_pause_root = null
	_set_frozen(false)
	_touch.queue_redraw()
	_update_hud()
