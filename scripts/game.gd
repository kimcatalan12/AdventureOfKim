extends Node
## Screen switching, saved progress, settings and input setup.

const SAVE_PATH := "user://save.cfg"
const STAGE_COUNT := 3
enum TouchStyle { JOYSTICK, ARROWS, HIDDEN }

var host: Node
var screen: Control
var touch_vector := Vector2.ZERO
var theme: Theme
var saving_enabled := true

var unlocked := 1
var seen_intro := false
var finished := false
var best_scores := {}
var muted := false
var music_level := 0.7
var effects_level := 0.9
var touch_style := TouchStyle.HIDDEN
## Shuffled indexes still to show, by deck name (for example "facts1").
var decks := {}


func _ready() -> void:
	_add_action("move_left", [KEY_LEFT, KEY_A])
	_add_action("move_right", [KEY_RIGHT, KEY_D])
	_add_action("move_up", [KEY_UP, KEY_W])
	_add_action("move_down", [KEY_DOWN, KEY_S])
	_add_action("pause", [KEY_ESCAPE, KEY_P])
	touch_style = TouchStyle.JOYSTICK if DisplayServer.is_touchscreen_available() else TouchStyle.HIDDEN
	load_progress()
	theme = UI.make_theme()
	get_tree().root.theme = theme
	if OS.is_debug_build() and _bot_requested():
		saving_enabled = false
		add_child(load("res://tests/bot.gd").new())


func go(screen_name: String, screen_args := {}) -> void:
	if screen:
		screen.queue_free()
	touch_vector = Vector2.ZERO
	host.get_viewport().canvas_transform = Transform2D.IDENTITY
	screen = load("res://scripts/screens/%s.gd" % screen_name).new()
	screen.theme = theme
	screen.args = screen_args
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.add_child(screen)


func load_stage(number: int) -> Dictionary:
	return _read_json("res://data/stage%d.json" % number)


func load_story(key: String) -> Array:
	return _read_json("res://data/story.json")[key]


func record_pass(stage: int, score: int) -> void:
	best_scores[stage] = maxi(int(best_scores.get(stage, 0)), score)
	if stage < STAGE_COUNT:
		unlocked = maxi(unlocked, stage + 1)
	else:
		finished = true
	save_progress()


## Returns the next index (0 to count - 1) from a shuffled deck. Each index
## comes up once before any repeats, and the deck is saved between runs.
func draw_from_deck(deck_name: String, count: int) -> int:
	var deck: Array = decks.get(deck_name, []).filter(func(i: int) -> bool: return i < count)
	if deck.is_empty():
		deck = range(count)
		deck.shuffle()
	var index: int = deck.pop_back()
	decks[deck_name] = deck
	save_progress()
	return index


func save_progress() -> void:
	if not saving_enabled:
		return
	var file := ConfigFile.new()
	file.set_value("progress", "unlocked", unlocked)
	file.set_value("progress", "seen_intro", seen_intro)
	file.set_value("progress", "finished", finished)
	file.set_value("progress", "best_scores", best_scores)
	file.set_value("progress", "decks", decks)
	file.set_value("settings", "muted", muted)
	file.set_value("settings", "music_level", music_level)
	file.set_value("settings", "effects_level", effects_level)
	file.set_value("settings", "touch_style", touch_style)
	file.save(SAVE_PATH)


func load_progress() -> void:
	var file := ConfigFile.new()
	if file.load(SAVE_PATH) != OK:
		return
	unlocked = file.get_value("progress", "unlocked", unlocked)
	seen_intro = file.get_value("progress", "seen_intro", seen_intro)
	finished = file.get_value("progress", "finished", finished)
	best_scores = file.get_value("progress", "best_scores", best_scores)
	decks = file.get_value("progress", "decks", decks)
	muted = file.get_value("settings", "muted", muted)
	music_level = file.get_value("settings", "music_level", music_level)
	effects_level = file.get_value("settings", "effects_level", effects_level)
	touch_style = file.get_value("settings", "touch_style", touch_style)


func _read_json(path: String) -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func _add_action(action: String, keys: Array) -> void:
	InputMap.add_action(action)
	for key: int in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key as Key
		InputMap.action_add_event(action, event)


func _bot_requested() -> bool:
	if "--bot" in OS.get_cmdline_user_args():
		return true
	if OS.has_feature("web"):
		return "bot=1" in str(JavaScriptBridge.eval("location.search"))
	return false
