extends Node
## Renders the itch.io page images from the game's own art:
##   cover.png       630 x 500   (cover image)
##   banner.png      960 x 240   (top of the page)
##   background.png  256 x 256   (tiles behind the page)
## Run (needs a window, not --headless):
##   godot --path . tools/itch_art.tscn -- --out=build/itch
## Everything is drawn at 2x, then scaled down for smooth edges.

const SKY := Color("3db3e3")
const SKY_LIGHT := Color("a7def3")
const GRASS := Color("55c16e")
const GRASS_DARK := Color("3f9e57")


func _ready() -> void:
	_render_all.call_deferred()


func _render_all() -> void:
	var out := "build/itch"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	await _render(Vector2i(630, 500), _draw_cover, out + "/cover.png")
	await _render(Vector2i(960, 240), _draw_banner, out + "/banner.png")
	await _render(Vector2i(256, 256), _draw_background, out + "/background.png")
	get_tree().quit()


func _render(out_size: Vector2i, draw: Callable, path: String) -> void:
	var size := out_size * 2
	var viewport := SubViewport.new()
	viewport.size = size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(viewport)
	var page := Control.new()
	page.theme = UI.make_theme()
	page.size = size
	viewport.add_child(page)
	draw.call(page)
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	image.resize(out_size.x, out_size.y, Image.INTERPOLATE_LANCZOS)
	image.save_png(path)
	print("saved: ", path)
	viewport.queue_free()


# ---------- cover ----------

func _draw_cover(page: Control) -> void:
	var width := page.size.x
	UI.background(page, "bg_school")
	_top_shade(page, 470)
	_text(page, "The Adventure", 118, Vector2(0, 30), width)
	_text(page, "of Kim", 132, Vector2(0, 160), width)
	_pill(page, "Fractions & Decimals", Vector2(width / 2.0, 385), UI.YELLOW, UI.INK, 46)
	# Kim and Vince stand on the path in front of the school.
	_sprite(page, "kim_down_1", Rect2(330, 480, 300, 375))
	_sprite(page, "vince", Rect2(640, 470, 300, 385))
	# Things Kim collects, floating around.
	_sprite(page, "book", Rect2(110, 520, 150, 150), -12.0)
	_sprite(page, "pencil", Rect2(1010, 500, 150, 150), 14.0)
	_sprite(page, "star", Rect2(1030, 760, 130, 130), -8.0)
	_sprite(page, "heart", Rect2(140, 790, 110, 110), 8.0)
	# A few math bits so the topic is clear at a glance.
	_pill(page, "3/4 = 0.75", Vector2(240, 940), Color.WHITE, UI.TEAL_DARK, 40)
	_pill(page, "1/2 + 1/4", Vector2(width / 2.0, 940), Color.WHITE, UI.TEAL_DARK, 40)
	_pill(page, "2.5 × 3", Vector2(1020, 940), Color.WHITE, UI.TEAL_DARK, 40)


# ---------- banner ----------

func _draw_banner(page: Control) -> void:
	var size := page.size
	_vertical_fade(page, Rect2(Vector2.ZERO, size), SKY, SKY_LIGHT)
	_cloud(page, Vector2(150, 70), 1.0)
	_cloud(page, Vector2(820, 40), 0.7)
	_cloud(page, Vector2(1500, 85), 0.9)
	# Grass along the bottom, with a darker edge.
	_box(page, Rect2(0, size.y - 92, size.x, 92), GRASS)
	_box(page, Rect2(0, size.y - 92, size.x, 8), GRASS_DARK)
	# Kim on the left, Vince on the right, standing on the grass.
	_sprite(page, "kim_down_1", Rect2(160, 190, 210, 262))
	_sprite(page, "vince", Rect2(size.x - 370, 182, 210, 270))
	_sprite(page, "book", Rect2(30, 280, 110, 110), -12.0)
	_sprite(page, "pencil", Rect2(size.x - 140, 260, 110, 110), 14.0)
	_sprite(page, "star", Rect2(380, 30, 80, 80), -10.0)
	_sprite(page, "heart", Rect2(size.x - 450, 40, 70, 70), 8.0)
	_text(page, "The Adventure of Kim", 92, Vector2(0, 112), size.x)
	_pill(page, "Fractions & Decimals", Vector2(size.x / 2.0, 318), UI.YELLOW, UI.INK, 42)


# ---------- background tile ----------

## A seamless tile: a symbol that crosses an edge is drawn again on the
## opposite side, so the tiles join without gaps or cut-off shapes.
func _draw_background(page: Control) -> void:
	_box(page, Rect2(Vector2.ZERO, page.size), SKY)
	var symbols := ["1/2", "+", "0.75", "÷", "×", "3/4", "−", "2.5", "1/4", "=", "0.5", "+", "÷", "2/3", "×", "1.2"]
	var cell := page.size.x / 4.0
	var ink := Color(1, 1, 1, 0.22)
	for i in symbols.size():
		var col := i % 4
		var row := i / 4
		# Offset every other row by half a cell for a scattered look.
		var x := (col + (0.25 if row % 2 == 0 else 0.75)) * cell
		var center := Vector2(x, (row + 0.5) * cell)
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				var label := UI.tag(symbols[i], 44 if symbols[i].length() == 1 else 34, ink)
				page.add_child(label)
				label.reset_size()
				label.pivot_offset = label.size / 2.0
				label.position = center + Vector2(dx, dy) * page.size - label.size / 2.0
				label.rotation_degrees = -14.0 if (i % 3 == 0) else (10.0 if i % 3 == 1 else 0.0)


# ---------- drawing helpers ----------

func _top_shade(page: Control, height: float) -> void:
	_vertical_fade(page, Rect2(0, 0, page.size.x, height), Color(UI.INK, 0.45), Color(UI.INK, 0.0))


func _vertical_fade(page: Control, rect: Rect2, top: Color, bottom: Color) -> void:
	var fade := Gradient.new()
	fade.set_color(0, top)
	fade.set_color(1, bottom)
	var texture := GradientTexture2D.new()
	texture.gradient = fade
	texture.fill_from = Vector2(0, 0)
	texture.fill_to = Vector2(0, 1)
	var node := TextureRect.new()
	node.texture = texture
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.position = rect.position
	node.size = rect.size
	page.add_child(node)


func _box(page: Control, rect: Rect2, color: Color) -> void:
	var node := ColorRect.new()
	node.color = color
	node.position = rect.position
	node.size = rect.size
	page.add_child(node)


## A soft white cloud made of three rounded blobs.
func _cloud(page: Control, at: Vector2, scale: float) -> void:
	for blob: Rect2 in [Rect2(0, 30, 200, 70), Rect2(40, 0, 100, 90), Rect2(100, 15, 90, 75)]:
		var panel := Panel.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color(1, 1, 1, 0.92)
		style.set_corner_radius_all(int(50 * scale))
		panel.add_theme_stylebox_override("panel", style)
		panel.position = at + blob.position * scale
		panel.size = blob.size * scale
		page.add_child(panel)


func _text(page: Control, words: String, size: int, at: Vector2, width: float) -> void:
	var label := UI.label(words, size, Color.WHITE, true)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.add_theme_color_override("font_outline_color", UI.INK)
	label.add_theme_constant_override("outline_size", 26)
	label.position = at
	label.size = Vector2(width, size * 1.3)
	page.add_child(label)


## A rounded label centered on `center`.
func _pill(page: Control, words: String, center: Vector2, fill: Color, ink: Color, size: int) -> void:
	var panel := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = UI.INK
	box.set_border_width_all(5)
	box.set_corner_radius_all(40)
	box.content_margin_left = 34
	box.content_margin_right = 34
	box.content_margin_top = 8
	box.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", box)
	panel.add_child(UI.tag(words, size, ink))
	page.add_child(panel)
	panel.reset_size()
	panel.position = center - panel.get_combined_minimum_size() / 2.0


func _sprite(page: Control, art: String, rect: Rect2, angle := 0.0) -> void:
	var image := UI.image(art, rect.size)
	image.position = rect.position
	image.size = rect.size
	image.pivot_offset = rect.size / 2.0
	image.rotation_degrees = angle
	page.add_child(image)
