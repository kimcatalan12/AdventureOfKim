extends Screen

var _settings_layer: Control


func _ready() -> void:
	UI.background(self, "bg_school")
	var box := UI.card(self, 360)
	box.add_child(UI.label("Main Menu", 32, UI.INK, true))
	var play := UI.button("Play", func() -> void: Game.go("select"))
	box.add_child(play)
	box.add_child(UI.button("Tutorial", func() -> void: Game.go("tutorial")))
	box.add_child(UI.button("About", func() -> void: Game.go("about")))
	box.add_child(UI.button("Settings", _open_settings))
	if not OS.has_feature("web"):
		box.add_child(UI.button("Exit", func() -> void: get_tree().quit()))
	play.grab_focus()


func _open_settings() -> void:
	_settings_layer = SettingsPanel.new()
	add_child(_settings_layer)
