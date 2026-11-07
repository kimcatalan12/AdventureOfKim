extends Screen

const TIPS := [
	["kim_down_1", "Move Kim", "Arrow keys or WASD. On touch screens, use the joystick or arrows."],
	["book", "Collect objects", "Walk over books and pencils. Each one teaches you a fact."],
	["rabbit_1", "Avoid enemies", "Rabbits hop around. Touching one costs a life saver."],
	["bat_1", "Watch the bats", "Bats fly over walls and follow Kim when he gets close."],
	["heart", "3 life savers", "Each question gets 3 attempts. A wrong answer sends you to find another object."],
	["star", "Pass the quiz", "Answer all 20 questions. Get at least 10 right on the first try."],
]


func _ready() -> void:
	UI.background(self, "bg_classroom")
	var box := UI.card(self, 860)
	box.add_child(UI.label("Tutorial", 30, UI.INK, true))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 14)
	box.add_child(grid)
	for tip: Array in TIPS:
		grid.add_child(_tip(tip))
	box.add_child(UI.button("Back", func() -> void: Game.go("menu")))


func _tip(tip: Array) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(UI.image(tip[0], Vector2(60, 60)))
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.custom_minimum_size.x = 320
	text.add_child(UI.label(tip[1], 20, UI.TEAL_DARK))
	text.add_child(UI.label(tip[2], 16, UI.INK))
	row.add_child(text)
	return row
