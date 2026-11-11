extends Screen

const ICONS := {1: "book", 2: "pencil", 3: "star"}


func _ready() -> void:
	UI.background(self, "bg_school")
	var box := UI.card(self, 760)
	box.add_child(UI.label("Choose a stage", 30, UI.INK, true))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	box.add_child(row)
	for number in range(1, Game.STAGE_COUNT + 1):
		row.add_child(_stage_column(number))
	if OS.has_feature("editor"):
		_add_test_row(box)
	box.add_child(UI.button("Back", func() -> void: Game.go("menu")))


## Only when running from the Godot editor, never in an exported game
## (not even a debug export, like a test APK). Lets you jump ahead to test later stages and cutscenes.
## Using a shortcut turns off saving until you close the game, so your real
## progress stays the same.
func _add_test_row(box: VBoxContainer) -> void:
	box.add_child(UI.label("Test shortcuts (editor only, progress is not saved)", 16, UI.MUTED, true))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	var shortcuts := {
		"Unlock all": func() -> void:
			Game.unlocked = Game.STAGE_COUNT
			Game.go("select"),
		"Cutscene + Stage 3": func() -> void:
			Game.go("story", {"key": "after2", "next": "lesson", "next_args": {"stage": 3}}),
		"Ending": func() -> void:
			for stage in range(1, Game.STAGE_COUNT + 1):
				Game.best_scores[stage] = maxi(int(Game.best_scores.get(stage, 0)), 15)
			Game.go("certificate"),
	}
	for text: String in shortcuts:
		var action: Callable = shortcuts[text]
		var button := UI.button(text, func() -> void:
			Game.saving_enabled = false
			action.call(), Vector2(0, 40))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 17)
		row.add_child(button)


func _stage_column(number: int) -> Control:
	var data := Game.load_stage(number)
	var open: bool = number <= Game.unlocked
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 8)
	column.add_child(UI.image(ICONS[number], Vector2(0, 64)))
	column.add_child(UI.label("Stage %d" % number, 18, UI.MUTED, true))
	column.add_child(UI.label(data["name"], 24, UI.INK, true))
	column.add_child(UI.label(data["topic"], 17, UI.MUTED, true))
	var best: int = Game.best_scores.get(number, 0)
	column.add_child(UI.label("Best: %d/20" % best if best > 0 else " ", 17, UI.GREEN, true))
	var play := UI.button("Stage %d" % number if open else "Locked", _start.bind(number))
	play.disabled = not open
	column.add_child(play)
	return column


func _start(number: int) -> void:
	if number == 1 and not Game.seen_intro:
		Game.seen_intro = true
		Game.save_progress()
		Game.go("story", {"key": "intro", "next": "lesson", "next_args": {"stage": 1}})
	else:
		Game.go("lesson", {"stage": number})
