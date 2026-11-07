class_name QuizQuestion
extends VBoxContainer
## One question. Shows four choices, or a typing box with a keypad when the
## question has no choices. Calls on_answer with true or false.

var question: Dictionary
var on_answer: Callable
var input: LineEdit


func _init(question_data: Dictionary, answer_callback: Callable) -> void:
	question = question_data
	on_answer = answer_callback


func _ready() -> void:
	add_theme_constant_override("separation", 12)
	add_child(UI.label(question["q"], 26, UI.INK, true))
	if question.has("choices"):
		_add_choices()
	else:
		_add_typing()


func _add_choices() -> void:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 12)
	var choices: Array = question["choices"].duplicate()
	choices.shuffle()
	for choice: String in choices:
		var button := UI.button(choice, _choose.bind(choice), Vector2(0, 54))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 24)
		grid.add_child(button)
	add_child(grid)


func _choose(choice: String) -> void:
	on_answer.call(choice == question["a"])


func _add_typing() -> void:
	input = LineEdit.new()
	input.placeholder_text = "Type your answer"
	input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	input.virtual_keyboard_enabled = false
	input.add_theme_font_size_override("font_size", 26)
	input.custom_minimum_size = Vector2(0, 52)
	input.text_submitted.connect(func(_text: String) -> void: _submit())
	add_child(input)
	var grid := GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for key: String in ["1", "2", "3", "4", "5", "/", "Space", "6", "7", "8", "9", "0", ".", "Del"]:
		var button := UI.button(key, _press_key.bind(key), Vector2(0, 46))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_NONE
		grid.add_child(button)
	add_child(grid)
	add_child(UI.button("Submit", _submit, Vector2(0, 50)))
	input.grab_focus.call_deferred()


func _press_key(key: String) -> void:
	match key:
		"Del":
			input.text = input.text.left(-1)
		"Space":
			input.text += " "
		_:
			input.text += key
	input.caret_column = input.text.length()


func _submit() -> void:
	if input.text.strip_edges().is_empty():
		return
	var correct := MathAnswer.same_value(input.text, question["a"])
	input.text = ""
	on_answer.call(correct)
