extends Node
## Debug builds only. Plays the whole game through the real screens and buttons.
## Desktop: godot --headless --path . -- --bot
## Web debug build: open the page with ?bot=1 (the result appears in the page title).

const STEP := 0.03

var _log := PackedStringArray()
var _shots_dir := ""


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			_shots_dir = arg.trim_prefix("--shots=")
			Game.muted = true
	_run.call_deferred()


func _shot(name: String) -> void:
	if _shots_dir.is_empty():
		return
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_shots_dir, name])


func _run() -> void:
	Game.unlocked = 1
	Game.seen_intro = false
	Game.best_scores = {}
	await _wait()
	await _press("Start")
	await _check_menu_pages()
	await _press("Play")
	await _press("Stage 1")
	await _shot("story")
	await _skip_story()
	for stage in [1, 2, 3]:
		await _play_stage(stage)
	_expect(Game.screen.get_script().resource_path.ends_with("certificate.gd"), "certificate shown")
	_note("certificate shown: " + str(_labels()))
	await _shot("certificate")
	await _press("Continue")
	await _skip_story()
	_expect(Game.screen.get_script().resource_path.ends_with("menu.gd"), "back at menu after ending")
	_expect(Game.finished, "game marked finished")
	await _check_test_shortcuts()
	_finish("BOT PASS")


## The editor-only shortcuts on the stage select screen.
func _check_test_shortcuts() -> void:
	await _press("Play")
	await _shot("select_test")
	await _press("Ending")
	_expect(_on("certificate.gd"), "Ending shortcut opens the certificate")
	await _press("Continue")
	await _skip_story()
	_expect(_on("menu.gd"), "ending cutscene returns to the menu")
	await _press("Play")
	await _press("Cutscene + Stage 3")
	_expect(_on("story.gd"), "shortcut plays the cutscene before stage 3")
	await _skip_story()
	_expect(_on("lesson.gd") and Game.screen.args["stage"] == 3, "cutscene leads to the stage 3 lesson")


func _on(script_name: String) -> bool:
	return Game.screen.get_script().resource_path.ends_with(script_name)


func _check_menu_pages() -> void:
	await _press("Tutorial")
	await _press("Back")
	await _press("About")
	await _press("Back")
	await _press("Settings")
	await _check_mute_hover()
	await _press("Done")
	if OS.has_feature("web"):
		_expect(_find_button("Exit") == null, "Exit hidden on web")


## Mute must keep its background when it is on and the mouse is over it.
func _check_mute_hover() -> void:
	var mute := _find_button("Mute all sound") as CheckButton
	_expect(mute != null, "mute toggle in settings")
	var was_muted := mute.button_pressed
	mute.button_pressed = true
	var style := mute.get_theme_stylebox("hover_pressed") as StyleBoxFlat
	_expect(style != null and style.bg_color.a > 0.0, "mute keeps a background on hover")
	var motion := InputEventMouseMotion.new()
	motion.position = get_tree().root.get_final_transform() * mute.get_global_rect().get_center()
	Input.parse_input_event(motion)
	await _wait(3)
	await _shot("mute_hover")
	mute.button_pressed = was_muted


func _play_stage(stage: int) -> void:
	await _lesson()
	_expect(Game.screen.stage_number == stage, "on stage %d" % stage)
	if stage == 1:
		await _test_controls()
		await _test_pause_and_enemy()
	await _collect_all()
	await _answer_all(stage)
	_expect(Game.screen.rules.phase == StageRules.Phase.PASSED, "stage %d passed" % stage)
	_note("stage %d passed, score %d" % [stage, Game.screen.rules.score])
	await _shot("clear")
	await _press("Continue")
	if stage < 3:
		await _skip_story()


func _lesson() -> void:
	await get_tree().create_timer(4.0 if not _shots_dir.is_empty() else 0.0).timeout
	await _shot("lesson_%d" % Game.screen.args["stage"])
	await _press("Skip to practice")
	await _shot("trial_%d" % Game.screen.args["stage"])
	var trial: Dictionary = Game.screen._data["trial"]
	await _give_wrong(trial)
	await _give_right(trial)
	await _wait()
	await _shot("ready")
	await _press("Start stage")
	await _wait()
	await get_tree().create_timer(1.0 if not _shots_dir.is_empty() else 0.0).timeout
	await _shot("map_%d" % Game.screen.stage_number)


func _test_controls() -> void:
	var stage: Screen = Game.screen
	_park_enemies(stage)
	await _hold_key(KEY_RIGHT, Vector2.RIGHT, "arrow key")
	await _hold_key(KEY_A, Vector2.LEFT, "WASD key")
	# Walls: walk left until blocked; Kim must stop at the wall, not pass it.
	stage.player.position = _left_wall_spot(stage)
	var press := _key(KEY_LEFT, true)
	Input.parse_input_event(press)
	await _wait(60)
	Input.parse_input_event(_key(KEY_LEFT, false))
	await _wait(2)
	_expect(stage.player.position.x >= 48 and stage.player.position.x < 90, "wall stops Kim, x=%s" % stage.player.position.x)
	# Touch controls.
	Game.touch_style = Game.TouchStyle.JOYSTICK
	stage._touch.queue_redraw()
	await _shot("joystick")
	await _hold_touch(TouchControls.JOY_CENTER, TouchControls.JOY_CENTER + Vector2(60, 0), Vector2.RIGHT, "joystick")
	Game.touch_style = Game.TouchStyle.ARROWS
	stage._touch.queue_redraw()
	await _shot("arrows")
	await _hold_touch(TouchControls.ARROW_CENTER, TouchControls.ARROW_CENTER + Vector2(0, 50), Vector2.DOWN, "touch arrows")
	Game.touch_style = Game.TouchStyle.HIDDEN
	stage.player.position = _start_point(stage)
	for enemy: Enemy in stage.enemies:
		enemy.frozen = false
	await _wait()


func _key(code: Key, pressed: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	return event


func _hold_key(code: Key, direction: Vector2, what: String) -> void:
	var player: Player = Game.screen.player
	player.position = _open_spot(Game.screen)
	var before := player.position
	Input.parse_input_event(_key(code, true))
	await _wait(12)
	Input.parse_input_event(_key(code, false))
	await _wait(2)
	_expect((player.position - before).dot(direction) > 20.0, what + " moves Kim")


func _hold_touch(start: Vector2, end: Vector2, direction: Vector2, what: String) -> void:
	var player: Player = Game.screen.player
	player.position = _open_spot(Game.screen)
	var before := player.position
	# Events arrive in window coordinates; the headless window is much smaller.
	var to_window := get_tree().root.get_final_transform()
	start = to_window * start
	end = to_window * end
	var down := InputEventScreenTouch.new()
	down.position = start
	down.pressed = true
	Input.parse_input_event(down)
	var drag := InputEventScreenDrag.new()
	drag.position = end
	Input.parse_input_event(drag)
	await _wait(12)
	var up := InputEventScreenTouch.new()
	up.position = end
	up.pressed = false
	Input.parse_input_event(up)
	await _wait(2)
	_expect((player.position - before).dot(direction) > 20.0, what + " moves Kim")
	_expect(Game.touch_vector == Vector2.ZERO, what + " stops on release")


func _test_pause_and_enemy() -> void:
	var stage: Screen = Game.screen
	await _press("Pause")
	await _shot("pause")
	await _press("Settings")
	await _shot("settings")
	await _press("Done")
	await _press("Resume")
	var enemy: Enemy = stage.enemies[0]
	stage.player.position = enemy.position
	stage.player.start_blink(0.0)
	await _wait(3)
	_expect(stage.rules.lives == 2, "touching an enemy costs a life saver")
	stage.player.position = _start_point(stage)
	await _wait()


func _collect_all() -> void:
	var stage: Screen = Game.screen
	while stage.rules.phase == StageRules.Phase.COLLECT:
		_move_away_from_enemies(stage)
		stage.player.position = stage.collectibles[0].position
		await _wait(3)
		await _shot("fact")
		var button := _find_button("Start the quiz")
		if button == null:
			button = _find_button("OK")
		_expect(button != null, "fact pop-up after pick up")
		button.pressed.emit()
		await _wait()


func _answer_all(stage_number: int) -> void:
	var stage: Screen = Game.screen
	var first := true
	while stage.rules.phase == StageRules.Phase.QUIZ:
		var question: Dictionary = stage.questions[stage.rules.question_index]
		if first:
			await _shot("quiz_%d" % stage_number)
			first = false
			await _give_wrong(question)
			_expect(stage.rules.phase == StageRules.Phase.SEEK, "wrong answer sends player to seek")
			await _shot("seek")
			await _press("OK")
			_move_away_from_enemies(stage)
			stage.player.position = stage.collectibles[0].position
			await _wait(3)
			await _press("Back to the question")
			_expect(stage.rules.phase == StageRules.Phase.QUIZ, "object reopens the question")
			_expect(stage.questions[stage.rules.question_index] == question, "same question comes back")
		await _give_right(question)
		await _wait()
	_expect(stage.rules.score == 19, "stage %d score is 19 after one retry" % stage_number)


func _move_away_from_enemies(stage: Screen) -> void:
	_park_enemies(stage)
	stage.player.start_blink(0.0)


## Freezes the enemies far outside the map so they can't touch Kim.
func _park_enemies(stage: Screen) -> void:
	for enemy: Enemy in stage.enemies:
		enemy.position = Vector2(-1000, -1000) + Vector2(randf() * 40.0, 0)
		enemy.frozen = true


# The map is random, so the bot looks for floor instead of using fixed spots.

## Open floor with nothing on it.
func _is_floor(stage: Screen, cell: Vector2i) -> bool:
	var map: PackedStringArray = stage.data["map"]
	if cell.y < 0 or cell.y >= map.size() or cell.x < 0 or cell.x >= map[0].length():
		return false
	# A book or pencil on the tile would open a fact pop-up mid-test.
	for item: Sprite2D in stage.collectibles:
		if Vector2i((item.position / 48.0).floor()) == cell:
			return false
	return map[cell.y][cell.x] in [".", "P"]


func _cell_center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * 48.0


func _start_point(stage: Screen) -> Vector2:
	var map: PackedStringArray = stage.data["map"]
	for y in map.size():
		var x := map[y].find("P")
		if x >= 0:
			return _cell_center(Vector2i(x, y))
	return Vector2(72, 72)


## A floor tile with open floor three tiles left, right and down.
func _open_spot(stage: Screen) -> Vector2:
	var map: PackedStringArray = stage.data["map"]
	for y in map.size():
		for x in map[0].length():
			var ok := true
			for i in range(-3, 4):
				ok = ok and _is_floor(stage, Vector2i(x + i, y))
			for i in range(0, 4):
				ok = ok and _is_floor(stage, Vector2i(x, y + i))
			if ok:
				return _cell_center(Vector2i(x, y))
	_expect(false, "map has an open spot")
	return Vector2.ZERO


## Four floor tiles in a row next to the left wall, for the wall test.
func _left_wall_spot(stage: Screen) -> Vector2:
	var map: PackedStringArray = stage.data["map"]
	for y in range(1, map.size() - 1):
		var ok := true
		for x in range(1, 5):
			ok = ok and _is_floor(stage, Vector2i(x, y))
		if ok:
			return _cell_center(Vector2i(4, y))
	_expect(false, "map has a clear row by the left wall")
	return Vector2.ZERO


func _give_right(question: Dictionary) -> void:
	if question.has("choices"):
		await _press(question["a"])
	else:
		await _type(question["a"])


func _give_wrong(question: Dictionary) -> void:
	if question.has("choices"):
		for choice: String in question["choices"]:
			if choice != question["a"]:
				await _press(choice)
				return
	else:
		await _type("99")


func _type(text: String) -> void:
	for ch in text:
		await _press("Space" if ch == " " else ch)
	await _press("Submit")


func _skip_story() -> void:
	await _wait()
	var guard := 0
	while Game.screen.get_script().resource_path.ends_with("story.gd") and guard < 30:
		await _press("Next")
		guard += 1


func _press(text: String) -> void:
	await _wait()
	var button := _find_button(text)
	if button == null:
		_finish("BOT FAIL: no button '%s' on %s. Labels: %s" % [text, Game.screen.get_script().resource_path, _labels()])
		await get_tree().create_timer(3600).timeout
	button.pressed.emit()
	await _wait()


func _find_button(text: String) -> Button:
	return _search(Game.screen, text)


func _search(node: Node, text: String) -> Button:
	for child in node.get_children():
		if child.is_queued_for_deletion():
			continue
		if child is Button and child.text == text and child.is_visible_in_tree() and not child.disabled:
			return child
		var found := _search(child, text)
		if found:
			return found
	return null


func _labels() -> Array:
	var out := []
	_collect_labels(Game.screen, out)
	return out


func _collect_labels(node: Node, out: Array) -> void:
	for child in node.get_children():
		if child is Label and not child.is_queued_for_deletion():
			out.append(child.text)
		_collect_labels(child, out)


func _wait(frames := 2) -> void:
	for i in frames:
		await get_tree().create_timer(STEP).timeout


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_finish("BOT FAIL: " + message)
		await get_tree().create_timer(3600).timeout


func _note(message: String) -> void:
	print(message)
	_log.append(message)


func _finish(result: String) -> void:
	print(result)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("document.title = %s" % JSON.stringify(result))
	else:
		get_tree().quit(0 if result == "BOT PASS" else 1)
