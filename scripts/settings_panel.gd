class_name SettingsPanel
extends Control
## Sound and on-screen control options, used by the menu and the pause screen.


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UI.dim(self)
	var box := UI.card(self, 480)
	box.add_child(UI.label("Settings", 30, UI.INK, true))
	box.add_child(_slider("Music", Game.music_level, func(value: float) -> void: Game.music_level = value))
	box.add_child(_slider("Effects", Game.effects_level, func(value: float) -> void: Game.effects_level = value))
	var mute := CheckButton.new()
	mute.text = "Mute all sound"
	mute.add_theme_color_override("font_color", Color.WHITE)
	mute.add_theme_color_override("font_hover_color", Color.WHITE)
	mute.add_theme_color_override("font_pressed_color", Color.WHITE)
	mute.add_theme_color_override("font_focus_color", Color.WHITE)
	mute.button_pressed = Game.muted
	mute.toggled.connect(func(on: bool) -> void:
		Game.muted = on
		Audio.apply_settings())
	box.add_child(mute)
	var row := HBoxContainer.new()
	row.add_child(UI.tag("Touch controls", 20))
	var choice := OptionButton.new()
	choice.add_item("Joystick", Game.TouchStyle.JOYSTICK)
	choice.add_item("Arrows", Game.TouchStyle.ARROWS)
	choice.add_item("Hidden", Game.TouchStyle.HIDDEN)
	choice.select(choice.get_item_index(Game.touch_style))
	choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choice.item_selected.connect(func(index: int) -> void:
		Game.touch_style = choice.get_item_id(index) as Game.TouchStyle)
	row.add_child(choice)
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)
	box.add_child(UI.button("Done", _close))


func _slider(title: String, value: float, apply: Callable) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var name_label := UI.tag(title, 20)
	name_label.custom_minimum_size.x = 90
	row.add_child(name_label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value_changed.connect(func(new_value: float) -> void:
		apply.call(new_value)
		Audio.apply_settings())
	row.add_child(slider)
	return row


func _close() -> void:
	Game.save_progress()
	var stage := get_parent()
	if stage.has_method("on_settings_closed"):
		stage.on_settings_closed()
	queue_free()
