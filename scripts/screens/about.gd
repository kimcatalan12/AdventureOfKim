extends Screen


func _ready() -> void:
	UI.background(self, "bg_classroom")
	var box := UI.card(self, 760)
	box.add_child(UI.label("About", 30, UI.INK, true))
	box.add_child(UI.label("Kim is a lazy Grade 5 student at Masigasig Academy who thinks math is too hard. When his best friend Vince convinces him to join the Math Club, Kim trains through three stages to master decimals and fractions.", 19))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)
	row.add_child(_character("kim_down_1", "Kim the General", "The main character. Single-player hero of the game."))
	row.add_child(_character("vince", "Vince", "Math Club president. Teaches the lessons and quizzes."))
	box.add_child(UI.label("Music and sound effects are original and were generated for this game.", 17, UI.MUTED))
	box.add_child(UI.button("Back", func() -> void: Game.go("menu")))


func _character(art: String, title: String, text: String) -> Control:
	var column := HBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(UI.image(art, Vector2(72, 90)))
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_child(UI.label(title, 20, UI.TEAL_DARK))
	words.add_child(UI.label(text, 16))
	column.add_child(words)
	return column
