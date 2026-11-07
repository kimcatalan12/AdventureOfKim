extends Screen
## Vince explains the topic with worked examples, then gives one practice
## question. The practice question has no penalty.

const STEP_SECONDS := 0.9

var _data: Dictionary
var _page := 0
var _text: Label
var _steps: VBoxContainer
var _content: VBoxContainer
var _next_button: Button
var _reveal_id := 0


func _ready() -> void:
	_data = Game.load_stage(args["stage"])
	UI.background(self, "bg_classroom")
	var vince := UI.image("vince", Vector2(150, 190))
	vince.position = Vector2(14, 320)
	vince.size = Vector2(150, 190)
	add_child(vince)
	var panel := PanelContainer.new()
	panel.position = Vector2(170, 24)
	panel.custom_minimum_size = Vector2(760, 492)
	panel.size = panel.custom_minimum_size
	add_child(panel)
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 12)
	panel.add_child(_content)
	_content.add_child(UI.label("Stage %d: %s — %s" % [args["stage"], _data["name"], _data["topic"]], 22, UI.TEAL_DARK))
	_text = UI.label("", 22)
	_content.add_child(_text)
	_steps = VBoxContainer.new()
	_steps.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_steps.add_theme_constant_override("separation", 6)
	_content.add_child(_steps)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 12)
	row.add_child(UI.button("Skip to practice", _show_trial, Vector2(190, 44)))
	_next_button = UI.button("Next", _next_page, Vector2(130, 44))
	row.add_child(_next_button)
	_content.add_child(row)
	_show_page()


func _show_page() -> void:
	_reveal_id += 1
	var page: Dictionary = _data["lesson"][_page]
	_text.text = page["text"]
	_clear(_steps)
	_reveal_steps(page["steps"], _reveal_id)


func _reveal_steps(steps: Array, id: int) -> void:
	for index in steps.size():
		if id != _reveal_id or not is_inside_tree():
			return
		var size := 34 if index == 0 else 24
		var color := UI.INK if index == 0 else UI.TEAL_DARK
		var line := UI.label(str(steps[index]), size, color, true)
		line.modulate.a = 0.0
		_steps.add_child(line)
		create_tween().tween_property(line, "modulate:a", 1.0, 0.35)
		await get_tree().create_timer(STEP_SECONDS).timeout


func _next_page() -> void:
	_page += 1
	if _page >= _data["lesson"].size():
		_show_trial()
	else:
		_show_page()


func _show_trial() -> void:
	_reveal_id += 1
	_clear(_content)
	_content.add_child(UI.label("Vince: Let's try one. No life savers at risk!", 22, UI.TEAL_DARK))
	var feedback := UI.label("", 21)
	var question := QuizQuestion.new(_data["trial"], func(correct: bool) -> void:
		if correct:
			Audio.play("correct")
			_show_ready()
		else:
			Audio.play("wrong")
			feedback.text = "Not quite. Try again!"
			feedback.add_theme_color_override("font_color", UI.RED))
	question.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_child(question)
	_content.add_child(feedback)


func _show_ready() -> void:
	_clear(_content)
	_content.add_child(UI.label("Great job! You're ready.", 30, UI.GREEN, true))
	var goal := []
	for item: String in _data["collect"]:
		goal.append("%d %ss" % [_data["collect"][item], item])
	var enemy_names := []
	for enemy: String in _data["enemies"]:
		enemy_names.append(enemy + "s")
	_content.add_child(UI.label("Find %s. Each one teaches you a fact." % " and ".join(goal), 22, UI.INK, true))
	_content.add_child(UI.label("Avoid the %s. You have 3 life savers." % " and ".join(enemy_names), 22, UI.INK, true))
	_content.add_child(UI.label("Then answer 20 questions. Get at least 10 right on the first try to pass.", 22, UI.INK, true))
	var start := UI.button("Start stage", func() -> void: Game.go("stage", {"stage": args["stage"]}), Vector2(0, 54))
	_content.add_child(start)
	start.grab_focus()


func _clear(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
