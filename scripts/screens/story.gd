extends Screen
## Plays one conversation from data/story.json, then moves to the next screen.

var _lines: Array
var _index := 0
var _speaker: Label
var _text: Label
var _background: TextureRect
var _kim: TextureRect
var _vince: TextureRect


func _ready() -> void:
	_lines = Game.load_story(args["key"])
	UI.background(self, "bg_school")
	_background = get_child(0)
	_kim = _portrait("kim_down_1", 120)
	_vince = _portrait("vince", 680)
	var panel := PanelContainer.new()
	panel.position = Vector2(40, 372)
	panel.custom_minimum_size = Vector2(880, 148)
	panel.size = panel.custom_minimum_size
	add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	_speaker = UI.label("", 22, UI.TEAL_DARK)
	box.add_child(_speaker)
	_text = UI.label("", 21)
	_text.custom_minimum_size = Vector2(840, 58)
	box.add_child(_text)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 12)
	row.add_child(UI.button("Skip", _finish, Vector2(100, 40)))
	row.add_child(UI.button("Next", _next, Vector2(130, 40)))
	box.add_child(row)
	_show_line()


func _portrait(art: String, x: float) -> TextureRect:
	var node := UI.image(art, Vector2(160, 200))
	node.position = Vector2(x, 164)
	node.size = Vector2(160, 200)
	add_child(node)
	return node


func _show_line() -> void:
	var line: Dictionary = _lines[_index]
	_speaker.text = line["who"]
	_text.text = line["text"]
	_background.texture = UI.tex(line.get("bg", "bg_school"))
	_kim.modulate = Color.WHITE if line["who"] != "Vince" else Color(0.65, 0.65, 0.65)
	_vince.modulate = Color.WHITE if line["who"] != "Kim" else Color(0.65, 0.65, 0.65)


func _next() -> void:
	_index += 1
	if _index >= _lines.size():
		_finish()
	else:
		_show_line()


func _finish() -> void:
	Game.go(args["next"], args.get("next_args", {}))
