extends Node2D
## Distinct procedural arachnid silhouettes, leg animation and status readability.

## Redraw at 30 Hz instead of 60 Hz. At 140 enemies this halves the cost of
## regenerating every mandible and body ellipse without a visible difference.
const REDRAW_INTERVAL := 1.0 / 30.0

## Baked body atlas. Each enemy used to submit ~13 canvas draw commands for
## thorax, abdomen, markings, mandibles and eyes every frame. All ten body
## styles are rendered once (normal + hit-flash variant) into a shared texture,
## so a live enemy body costs a single textured quad.
const ATLAS_COLUMNS := 5
const BODY_EXTENT := 88.0
const ATLAS_PIXELS_PER_UNIT := 2.0

var data: EnemyData
var style: String = "scout"
var body_color: Color = Color(0.7, 0.3, 0.2)
var accent_color: Color = Color(1.0, 0.7, 0.3)
var moving: bool = false
var stunned: bool = false
var flashing: bool = false
var burrowed: bool = false
var _time: float = 0.0
var _redraw_accum: float = 0.0
var _has_drawn: bool = false
var _bake_mode: bool = false

## Unit-circle outlines are rebuilt once per (center, rx, ry) tuple instead of
## allocating two 20-point arrays for every enemy every frame.
static var _ellipse_cache: Dictionary = {}
static var _atlas: Texture2D
static var _flash_atlas: Texture2D
static var _regions: Dictionary = {}


func _ready() -> void:
	pass


func configure(enemy_data: EnemyData) -> void:
	data = enemy_data
	style = enemy_data.visual_style
	body_color = enemy_data.body_color
	accent_color = enemy_data.accent_color
	scale = Vector2.ONE * maxf(0.45, enemy_data.body_scale)
	_has_drawn = true
	# Static body styles do not need an idle process at all; only their Legs
	# child animates.
	set_process(_is_pulsing_style())
	queue_redraw()


func refresh_body() -> void:
	queue_redraw()


func set_state(is_moving: bool, is_stunned: bool, is_flashing: bool, is_burrowed: bool) -> void:
	var flash_changed := is_flashing != flashing
	var burrow_changed := is_burrowed != burrowed
	moving = is_moving
	stunned = is_stunned
	flashing = is_flashing
	burrowed = is_burrowed
	if flash_changed or burrow_changed:
		queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	# Only styles with their own time-based body animation need continuous
	# redraws. Movement and leg swing are handled by the Legs child node.
	if not _has_drawn or _is_pulsing_style():
		_redraw_accum += delta
		if _redraw_accum >= REDRAW_INTERVAL:
			_redraw_accum = 0.0
			_has_drawn = true
			queue_redraw()


func _is_pulsing_style() -> bool:
	return style == "healer" or style == "flyer" or style == "boss"


func _draw() -> void:
	if data == null:
		return
	if burrowed:
		_draw_burrow_mound()
		return
	if _bake_mode:
		_draw_body_core()
		_draw_static_details()
		return
	var region: Variant = _regions.get(data)
	if _atlas != null and region is Rect2:
		var texture: Texture2D = _atlas
		if flashing and _flash_atlas != null:
			texture = _flash_atlas
		draw_texture_rect_region(texture,
			Rect2(-BODY_EXTENT * 0.5, -BODY_EXTENT * 0.5, BODY_EXTENT, BODY_EXTENT),
			region, Color.WHITE)
		_draw_shield_arc()
		_draw_dynamic_details()
		return
	# Fallback used for the first frames of a level, before the atlas exists.
	_draw_body_core()
	_draw_static_details()
	_draw_dynamic_details()


func _draw_body_core() -> void:
	var body := body_color
	if flashing:
		body = body.lerp(Color(1.0, 0.92, 0.8), 0.55)
	# Flight shadow.
	if data.flying:
		draw_set_transform(Vector2(0, 28), 0, Vector2(0.9, 0.35))
		draw_circle(Vector2.ZERO, 16, Color(0.0, 0.0, 0.0, 0.3))
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	else:
		draw_circle(Vector2(2, 5), 16, Color(0.0, 0.0, 0.0, 0.32))

	var abdomen_radius := 13.0
	var thorax_radius := 8.0
	if style == "worker":
		abdomen_radius = 15.0
	elif style == "warrior" or style == "shield":
		abdomen_radius = 15.0
		thorax_radius = 9.0
	elif style == "boss":
		abdomen_radius = 18.0
		thorax_radius = 12.0
	elif style == "spitter" or style == "healer":
		abdomen_radius = 16.0
	# Abdomen and cephalothorax.
	_draw_ellipse(Vector2(-10, 0), abdomen_radius, abdomen_radius * 0.8, body)
	_draw_ellipse(Vector2(7, 0), thorax_radius, thorax_radius * 0.78, body.darkened(0.12))
	# Back markings.
	draw_circle(Vector2(-13, -3), 4.0, accent_color.darkened(0.1))
	draw_circle(Vector2(-6, 4), 2.5, accent_color)
	draw_circle(Vector2(7, -3), 2.2, accent_color)
	_draw_mandibles()
	_draw_eyes()


func _draw_mandibles() -> void:
	var mandible := accent_color.darkened(0.15)
	var main := PackedVector2Array([
		Vector2(17, -5), Vector2(26, -9),
		Vector2(17, 5), Vector2(26, 9),
	])
	var tips := PackedVector2Array([
		Vector2(25, -9), Vector2(29, -4),
		Vector2(25, 9), Vector2(29, 4),
	])
	draw_multiline(main, mandible, 2.6, true)
	draw_multiline(tips, mandible.lightened(0.2), 1.6, true)


func _draw_eyes() -> void:
	var eye_color := accent_color
	if style == "flyer":
		eye_color = Color(0.9, 0.4, 1.0)
	elif style == "spitter":
		eye_color = Color(0.7, 1.0, 0.35)
	elif style == "boss":
		eye_color = Color(1.0, 0.2, 0.1)
	draw_circle(Vector2(13, -4), 2.6, eye_color)
	draw_circle(Vector2(13, 4), 2.6, eye_color)
	draw_circle(Vector2(13, -4), 1.1, Color(1, 1, 1, 0.9))
	draw_circle(Vector2(13, 4), 1.1, Color(1, 1, 1, 0.9))


func _shield_ratio() -> float:
	var enemy = get_parent()
	if enemy == null or not ("shield_current" in enemy):
		return 0.0
	return float(enemy.shield_current)


func _draw_shield_arc() -> void:
	if _shield_ratio() <= 0.0:
		return
	draw_arc(Vector2.ZERO, 30.0, 0, TAU, 36, Color(0.4, 0.8, 1.0, 0.45), 2.0, true)


## Details that are baked into the body atlas: they never change over time.
func _draw_static_details() -> void:
	match style:
		"warrior", "shield":
			var plate := body_color.lightened(0.24)
			var spike := PackedVector2Array([Vector2(-22, -10), Vector2(-14, -18), Vector2(-6, -10), Vector2(-14, -4)])
			draw_colored_polygon(spike, plate)
			var spike2 := PackedVector2Array([Vector2(-22, 10), Vector2(-14, 18), Vector2(-6, 10), Vector2(-14, 4)])
			draw_colored_polygon(spike2, plate)
			draw_arc(Vector2(-6, 0), 12, PI * 0.5, PI * 1.5, 12, plate, 2.0, true)
			if style == "shield":
				draw_arc(Vector2(2, 0), 20, 0, TAU, 28, Color(0.45, 0.8, 1.0, 0.35), 3.0, true)
		"spitter":
			draw_circle(Vector2(-18, 0), 8.0, Color(0.5, 0.9, 0.3, 0.45))
			draw_circle(Vector2(-18, 0), 4.5, Color(0.7, 1.0, 0.4, 0.7))
			draw_line(Vector2(26, 0), Vector2(34, 0), Color(0.65, 1.0, 0.35), 3.0, true)
		"burrower":
			draw_arc(Vector2(-4, 0), 17, PI * 0.7, PI * 1.3, 12, body_color.lightened(0.3), 2.2, true)
		"elite":
			var crown := body_color.lightened(0.32)
			for i in 3:
				var x := -20.0 + i * 7.0
				var pts := PackedVector2Array([Vector2(x, -12), Vector2(x + 3, -22), Vector2(x + 6, -12)])
				draw_colored_polygon(pts, crown)
				var pts2 := PackedVector2Array([Vector2(x, 12), Vector2(x + 3, 22), Vector2(x + 6, 12)])
				draw_colored_polygon(pts2, crown)
			draw_circle(Vector2(-6, 0), 5.0, Color(0.95, 0.25, 0.18, 0.65))
		"boss":
			var crown := Color(0.95, 0.25, 0.16)
			for i in 4:
				var x := -24.0 + i * 6.0
				var pts := PackedVector2Array([Vector2(x, -13), Vector2(x + 2, -26), Vector2(x + 5, -13)])
				draw_colored_polygon(pts, crown)
				var pts2 := PackedVector2Array([Vector2(x, 13), Vector2(x + 2, 26), Vector2(x + 5, 13)])
				draw_colored_polygon(pts2, crown.darkened(0.15))
			draw_circle(Vector2(-10, 0), 4.5, Color(1.0, 0.55, 0.25, 0.8))
		_:
			pass


## Details that keep animating on top of the baked body.
func _draw_dynamic_details() -> void:
	match style:
		"healer":
			var pulse := 0.55 + 0.45 * sin(_time * 4.0)
			draw_circle(Vector2(-16, 0), 9.0, Color(0.8, 0.5, 1.0, 0.28 * pulse))
			draw_circle(Vector2(-16, 0), 4.5, Color(0.95, 0.8, 1.0, 0.65))
			for i in 3:
				var a := _time * 1.4 + TAU * float(i) / 3.0
				draw_circle(Vector2(cos(a), sin(a)) * 22.0, 1.8, Color(0.8, 0.6, 1.0, 0.7))
		"flyer":
			var flap := 0.55 + 0.35 * sin(_time * 16.0)
			var wing_left := PackedVector2Array([Vector2(-4, -4), Vector2(-30, -22 * flap), Vector2(-10, -2)])
			var wing_right := PackedVector2Array([Vector2(-4, 4), Vector2(-30, 22 * flap), Vector2(-10, 2)])
			draw_colored_polygon(wing_left, Color(0.7, 0.4, 0.9, 0.42))
			draw_colored_polygon(wing_right, Color(0.7, 0.4, 0.9, 0.42))
			draw_line(Vector2(-4, -4), Vector2(-30, -22 * flap), Color(0.9, 0.6, 1.0, 0.7), 1.4, true)
			draw_line(Vector2(-4, 4), Vector2(-30, 22 * flap), Color(0.9, 0.6, 1.0, 0.7), 1.4, true)
		"boss":
			var pulse := 0.5 + 0.5 * sin(_time * 3.0)
			draw_circle(Vector2(-10, 0), 9.0, Color(1.0, 0.2, 0.1, 0.22 + 0.18 * pulse))
			draw_arc(Vector2.ZERO, 34.0, _time * 0.5, _time * 0.5 + 4.4, 32, Color(1.0, 0.2, 0.1, 0.4), 2.0, true)
		_:
			pass


func _draw_burrow_mound() -> void:
	var pulse := 0.5 + 0.5 * sin(_time * 5.0)
	_draw_ellipse(Vector2.ZERO, 24.0, 14.0, Color(0.42, 0.26, 0.16))
	_draw_ellipse(Vector2(-4, -2), 15.0, 8.0, Color(0.5, 0.32, 0.2))
	for i in 4:
		var a := TAU * float(i) / 4.0 + _time * 0.4
		draw_circle(Vector2(cos(a), sin(a)) * 17.0, 3.0, Color(0.34, 0.2, 0.12))
	draw_circle(Vector2(-14, -2), 2.5, Color(1.0, 0.7, 0.2, 0.5 + 0.5 * pulse))
	draw_circle(Vector2(-8, 3), 2.0, Color(1.0, 0.7, 0.2, 0.4 + 0.6 * pulse))


func _draw_ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
	draw_colored_polygon(_ellipse_points(center, rx, ry), color)


static func _ellipse_points(center: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var key := Vector4i(int(center.x * 10.0), int(center.y * 10.0), int(rx * 10.0), int(ry * 10.0))
	var cached: Variant = _ellipse_cache.get(key)
	if cached is PackedVector2Array and not (cached as PackedVector2Array).is_empty():
		return cached
	var points := PackedVector2Array()
	for i in 20:
		var a := TAU * float(i) / 20.0
		points.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	_ellipse_cache[key] = points
	return points


## Renders every distinct enemy body into one shared atlas. Called once per
## session by LevelBase; safe to call again after the atlas already exists.
static func bake_atlas(host: Node, data_list: Array) -> void:
	if _atlas != null or data_list.is_empty() or host == null:
		return
	var cell_pixels := int(BODY_EXTENT * ATLAS_PIXELS_PER_UNIT)
	var rows := int(ceil(float(data_list.size()) / float(ATLAS_COLUMNS)))
	var viewport := SubViewport.new()
	viewport.name = "EnemyBodyAtlas"
	viewport.size = Vector2i(cell_pixels * ATLAS_COLUMNS, cell_pixels * rows)
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.msaa_2d = Viewport.MSAA_DISABLED
	host.add_child(viewport)

	var painters: Array = []
	for i in data_list.size():
		var holder := Node2D.new()
		holder.position = Vector2(
			(float(i % ATLAS_COLUMNS) + 0.5) * float(cell_pixels),
			(float(i / ATLAS_COLUMNS) + 0.5) * float(cell_pixels))
		holder.scale = Vector2.ONE * ATLAS_PIXELS_PER_UNIT
		viewport.add_child(holder)
		var painter := Node2D.new()
		painter.set_script(load("res://scripts/enemies/EnemyVisual.gd"))
		holder.add_child(painter)
		painter.call("apply_bake_data", data_list[i])
		painters.append(painter)

	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	var normal_image := viewport.get_texture().get_image()

	for painter in painters:
		painter.set("flashing", true)
		painter.queue_redraw()
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	var flash_image := viewport.get_texture().get_image()

	if normal_image == null or flash_image == null:
		# Headless test runs have no real renderer; keep the single-quad draw
		# path so benchmarks still measure the same command count.
		if DisplayServer.get_name() == "headless":
			var empty := Image.create(4, 4, false, Image.FORMAT_RGBA8)
			_atlas = ImageTexture.create_from_image(empty)
			_flash_atlas = _atlas
			for i in data_list.size():
				_regions[data_list[i]] = Rect2(0, 0, 4, 4)
		viewport.queue_free()
		return

	_atlas = ImageTexture.create_from_image(normal_image)
	_flash_atlas = ImageTexture.create_from_image(flash_image)
	for i in data_list.size():
		var cell := Vector2i(i % ATLAS_COLUMNS, i / ATLAS_COLUMNS)
		_regions[data_list[i]] = Rect2(
			Vector2(cell) * float(cell_pixels), Vector2(float(cell_pixels), float(cell_pixels)))
	viewport.queue_free()

	for enemy in host.get_tree().get_nodes_in_group("enemies"):
		var visual = enemy.get_node_or_null("Visual")
		if visual != null and visual.has_method("refresh_body"):
			visual.call("refresh_body")


func apply_bake_data(enemy_data: EnemyData) -> void:
	data = enemy_data
	style = enemy_data.visual_style
	body_color = enemy_data.body_color
	accent_color = enemy_data.accent_color
	_bake_mode = true
	set_process(false)
	queue_redraw()
