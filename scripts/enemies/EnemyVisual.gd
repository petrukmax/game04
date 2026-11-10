extends Node2D
## Distinct procedural arachnid silhouettes, leg animation and status readability.

var data: EnemyData
var style: String = "scout"
var body_color: Color = Color(0.7, 0.3, 0.2)
var accent_color: Color = Color(1.0, 0.7, 0.3)
var moving: bool = false
var stunned: bool = false
var flashing: bool = false
var burrowed: bool = false
var _time: float = 0.0


func configure(enemy_data: EnemyData) -> void:
	data = enemy_data
	style = enemy_data.visual_style
	body_color = enemy_data.body_color
	accent_color = enemy_data.accent_color
	scale = Vector2.ONE * maxf(0.45, enemy_data.body_scale)
	queue_redraw()


func set_state(is_moving: bool, is_stunned: bool, is_flashing: bool, is_burrowed: bool) -> void:
	moving = is_moving
	stunned = is_stunned
	flashing = is_flashing
	burrowed = is_burrowed
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	if data == null:
		return
	var parent_enemy = get_parent()
	if burrowed:
		_draw_burrow_mound()
		return
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
	_draw_legs(body)

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
	_draw_style_details(parent_enemy)
	_draw_eyes()


func _draw_legs(body: Color) -> void:
	var limb := body.darkened(0.25)
	var joint := body.lightened(0.18)
	for side in [-1.0, 1.0]:
		for i in 4:
			var phase := _time * 9.0 + float(i) * 1.3 + (0.0 if side > 0.0 else PI)
			var swing := sin(phase) * 3.5 if moving and not stunned else 0.0
			var base_x := -12.0 + float(i) * 7.5
			var knee := Vector2(base_x + swing, side * (12.0 + float(i % 2) * 3.0))
			var foot := Vector2(base_x + swing * 1.7 + 3.0, side * (24.0 + float(i % 2) * 4.0))
			draw_line(Vector2(base_x, side * 5.0), knee, limb, 3.4, true)
			draw_line(knee, foot, limb.lightened(0.12), 2.0, true)
			draw_circle(knee, 1.7, joint)


func _draw_mandibles() -> void:
	var mandible := accent_color.darkened(0.15)
	draw_line(Vector2(17, -5), Vector2(26, -9), mandible, 2.6, true)
	draw_line(Vector2(17, 5), Vector2(26, 9), mandible, 2.6, true)
	draw_line(Vector2(25, -9), Vector2(29, -4), mandible.lightened(0.2), 1.6, true)
	draw_line(Vector2(25, 9), Vector2(29, 4), mandible.lightened(0.2), 1.6, true)


func _draw_eyes() -> void:
	var parent_enemy = get_parent()
	var shield: float = parent_enemy.shield_current if parent_enemy else 0.0
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
	if shield > 0.0:
		draw_arc(Vector2.ZERO, 30.0, 0, TAU, 36, Color(0.4, 0.8, 1.0, 0.45), 2.0, true)


func _draw_style_details(parent_enemy) -> void:
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
			var pulse := 0.5 + 0.5 * sin(_time * 3.0)
			draw_circle(Vector2(-10, 0), 9.0, Color(1.0, 0.2, 0.1, 0.22 + 0.18 * pulse))
			draw_circle(Vector2(-10, 0), 4.5, Color(1.0, 0.55, 0.25, 0.8))
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
	var points := PackedVector2Array()
	for i in 20:
		var a := TAU * float(i) / 20.0
		points.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(points, color)
