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
	box.add_child(UI.button("Back", func() -> void: Game.go("menu")))


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
