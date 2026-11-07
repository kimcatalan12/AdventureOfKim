extends Screen


func _ready() -> void:
	UI.background(self, "bg_school")
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	center.add_child(box)
	var title := UI.label("The Adventure of Kim", 58, Color.WHITE, true)
	title.custom_minimum_size.x = 900
	title.add_theme_color_override("font_outline_color", UI.INK)
	title.add_theme_constant_override("outline_size", 14)
	box.add_child(title)
	var tag := UI.label("A math quest in fractions and decimals", 22, Color.WHITE, true)
	tag.custom_minimum_size.x = 900
	tag.add_theme_color_override("font_outline_color", UI.INK)
	tag.add_theme_constant_override("outline_size", 8)
	box.add_child(tag)
	var row := CenterContainer.new()
	var start := UI.button("Start", _on_start, Vector2(220, 58))
	row.add_child(start)
	box.add_child(row)
	start.grab_focus()


func _on_start() -> void:
	Audio.start_music()
	Game.go("menu")
