class_name UI
extends RefCounted
## Colors and small helpers shared by every screen. Change the look here.

const INK := Color("1f2440")
const PANEL := Color("fff8e7")
const TEAL := Color("1fb5a6")
const TEAL_DARK := Color("158a80")
const YELLOW := Color("ffd166")
const RED := Color("e4484d")
const GREEN := Color("2f9e5b")
const MUTED := Color("5c6280")


static func make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 20
	theme.set_stylebox("normal", "Button", _box(TEAL, 12, TEAL_DARK))
	theme.set_stylebox("hover", "Button", _box(TEAL.lightened(0.15), 12, TEAL_DARK))
	theme.set_stylebox("pressed", "Button", _box(TEAL_DARK, 12, TEAL_DARK))
	# Used by toggles (like Mute) when they are on and hovered.
	theme.set_stylebox("hover_pressed", "Button", _box(TEAL_DARK.lightened(0.12), 12, TEAL_DARK))
	theme.set_stylebox("focus", "Button", _box(Color(0, 0, 0, 0), 12, YELLOW))
	theme.set_stylebox("disabled", "Button", _box(Color("b8bccb"), 12, Color("9a9eae")))
	theme.set_color("font_color", "Button", Color.WHITE)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", Color.WHITE)
	theme.set_color("font_hover_pressed_color", "Button", Color.WHITE)
	theme.set_color("font_focus_color", "Button", Color.WHITE)
	theme.set_color("font_disabled_color", "Button", Color("eceef5"))
	theme.set_stylebox("panel", "PanelContainer", _box(PANEL, 18, YELLOW))
	theme.set_color("font_color", "Label", INK)
	theme.set_stylebox("normal", "LineEdit", _box(Color.WHITE, 10, TEAL))
	theme.set_stylebox("focus", "LineEdit", _box(Color(0, 0, 0, 0), 10, YELLOW))
	theme.set_color("font_color", "LineEdit", INK)
	theme.set_color("caret_color", "LineEdit", INK)
	return theme


static func _box(color: Color, radius: int, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	box.set_border_width_all(3)
	box.border_color = border
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	return box


static func tex(name: String) -> Texture2D:
	return load("res://art/%s.svg" % name)


static func label(text: String, size := 20, color := INK, center := false) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if center:
		node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return node


static func button(text: String, action: Callable, min_size := Vector2(0, 46)) -> Button:
	var node := Button.new()
	node.text = text
	node.custom_minimum_size = min_size
	node.pressed.connect(func() -> void: Audio.play("click"))
	node.pressed.connect(action)
	return node


static func image(name: String, size: Vector2) -> TextureRect:
	var node := TextureRect.new()
	node.texture = tex(name)
	node.custom_minimum_size = size
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return node


static func background(parent: Control, name: String) -> void:
	var node := TextureRect.new()
	node.texture = tex(name)
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(node)


## A centered card. Add content to the box this returns.
static func card(parent: Node, width: float) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = width
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	return box


## Dims the screen behind a pop-up. Blocks clicks from reaching what's behind.
static func dim(parent: Node) -> ColorRect:
	var shade := ColorRect.new()
	shade.color = Color(0.07, 0.08, 0.16, 0.65)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(shade)
	return shade


## A one-line label for use inside rows, where a wrapping label would collapse.
static func tag(text: String, size := 20, color := INK) -> Label:
	var node := label(text, size, color)
	node.autowrap_mode = TextServer.AUTOWRAP_OFF
	return node
