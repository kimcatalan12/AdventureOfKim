extends Screen


func _ready() -> void:
	Audio.play("win")
	UI.background(self, "bg_classroom")
	var sheet := TextureRect.new()
	sheet.texture = UI.tex("certificate")
	sheet.position = Vector2(120, 20)
	sheet.size = Vector2(720, 440)
	add_child(sheet)
	_line("Certificate of Completion", 38, 70)
	_line("This certifies that", 20, 140)
	_line("Kim the General", 44, 172)
	_line("has completed all three stages of The Adventure of Kim", 20, 244)
	_line("and earned the rank of Grand Master", 20, 274)
	_line("in Fractions and Decimals.", 20, 304)
	var scores := []
	for stage in range(1, Game.STAGE_COUNT + 1):
		scores.append("Stage %d: %d/20" % [stage, int(Game.best_scores.get(stage, 0))])
	_line("   ·   ".join(scores), 18, 356)
	var next := UI.button("Continue", _on_continue, Vector2(240, 52))
	next.position = Vector2(360, 474)
	next.size = Vector2(240, 52)
	add_child(next)
	next.grab_focus()


func _line(text: String, size: int, y: float) -> void:
	var node := UI.label(text, size, UI.INK, true)
	node.position = Vector2(150, y)
	node.size = Vector2(660, 40)
	add_child(node)


func _on_continue() -> void:
	Game.go("story", {"key": "ending", "next": "menu"})
