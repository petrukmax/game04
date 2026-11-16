extends Node2D
## Procedural top-down tower art. One script, ten unmistakable silhouettes.
##
## Every style is baked once per session into a shared atlas with three layers
## (body, deco, turret), and a live tower only keeps three textured quads: the
## turret quad is rotated by the aim angle, the deco quad spins, sweeps, breathes,
## charges or pulses with cheap transform/modulate updates, and the selection
## ring / upgrade pips live in a separate overlay item that is redrawn only when
## they actually change. Every style owns a distinct deco motion and upgrades
## reuse the same style, so a Mk 4 tower keeps the animation of its base form.
## Nothing re-records vector draw commands during a match any more: the old
## implementation rebuilt ~20 canvas commands at 24 Hz for the animated styles
## and, because the disabled flag was pushed every physics frame, once per frame
## for every tower in play. Before the atlas exists (first frames of a level, or
## a headless run) the same painters draw immediately, so the fallback and the
## baked art can never drift apart.

const STYLES: Array[String] = [
	"pulse", "cannon", "flame", "tesla", "missile", "cryo", "rail", "relay", "mine", "orbital",
]
const LAYERS: Array[String] = ["body", "deco", "turret"]
## Deco layers that spin at this many radians per second of game time.
const DECO_SPIN := {"tesla": 1.8, "cryo": 0.35, "orbital": -1.5, "cannon": 0.55}
## Deco layers that pulse their alpha at this rate.
const DECO_PULSE := {"relay": 3.0, "mine": 5.0, "flame": 7.0}
## Deco layers whose alpha flickers irregularly (two detuned sines).
const DECO_FLICKER := ["flame"]
## Deco layers that sweep back and forth instead of spinning (rad/s).
const DECO_SWEEP := {"missile": 1.3}
## Deco layers that charge up: the ring expands and fades (cycles per second).
const DECO_CHARGE := {"rail": 0.6}
## Deco layers that breathe in place (scale cycle per second).
const DECO_BREATH := {"pulse": 2.6}
const SWEEP_AMPLITUDE := 0.55

const BAKE_CELL_UNITS := 88.0
const BAKE_PIXELS_PER_UNIT := 2.0
const BAKE_CELL_PIXELS: int = int(BAKE_CELL_UNITS * BAKE_PIXELS_PER_UNIT)
const FALLBACK_REDRAW := 1.0 / 24.0
const OVERLAY_REDRAW := 1.0 / 15.0
const KICK_TIME := 0.12

var data: TowerData
var style: String = "pulse"
var aim: float = 0.0
var kick_timer: float = 0.0
var selected: bool = false
var disabled: bool = false

var _time: float = 0.0
var _fallback_accum: float = 0.0
var _overlay_accum: float = 0.0

## Live deco animation state, cached once per tower so the per-frame path only
## branches on an int instead of hashing the style dictionaries.
enum DecoAnim { NONE, SPIN, PULSE, SWEEP, CHARGE, BREATH }
var _deco_anim: int = DecoAnim.NONE
var _deco_rate: float = 0.0
var _deco_flicker: bool = false

var _body_sprite: Sprite2D
var _deco_sprite: Sprite2D
var _turret_sprite: Sprite2D
var _overlay: Node2D

## Bake painter state. Only used by throwaway nodes inside a SubViewport.
var _bake_mode: bool = false
var _bake_layer: String = "body"
var _bake_color: Color = Color.WHITE
var _bake_time: float = 0.0

static var _atlas: Texture2D
static var _regions: Dictionary = {}


func _ready() -> void:
	if _bake_mode:
		return
	set_process(false)


func configure(tower_data: TowerData) -> void:
	data = tower_data
	style = tower_data.visual_style
	_deco_anim = _anim_kind(style)
	_deco_rate = _anim_rate(style, _deco_anim)
	_deco_flicker = DECO_FLICKER.has(style)
	if not _bake_mode:
		_build_sprites()
	_apply_art()


func set_aim(value: float) -> void:
	if _turret_sprite != null and _turret_sprite.visible:
		if absf(angle_difference(aim, value)) < 0.001:
			return
		aim = value
		_turret_sprite.rotation = value
		if kick_timer > 0.0:
			_turret_sprite.position = _recoil_offset()
		return
	if absf(angle_difference(aim, value)) < 0.001:
		return
	aim = value
	# No atlas yet: the fallback painter needs a redraw to show the new angle.
	if _atlas == null:
		queue_redraw()


func kick() -> void:
	kick_timer = KICK_TIME
	if _turret_sprite != null:
		_turret_sprite.position = _recoil_offset()
	else:
		queue_redraw()
	set_process(true)


func set_selected(value: bool) -> void:
	if selected == value:
		return
	selected = value
	_refresh_overlay()


func set_disabled(value: bool) -> void:
	if disabled == value:
		return
	disabled = value
	_refresh_overlay()
	_refresh_process()


func on_upgrade() -> void:
	kick_timer = 0.3
	_refresh_overlay()
	if _turret_sprite != null:
		_turret_sprite.position = _recoil_offset()
	set_process(true)
	# The relay aura radius grows with its level.
	queue_redraw()


## Switches a live tower to the baked atlas once it exists.
func refresh_art() -> void:
	_apply_art()


func _process(delta: float) -> void:
	_time += delta
	if kick_timer > 0.0:
		kick_timer = maxf(0.0, kick_timer - delta)
		if _turret_sprite != null:
			_turret_sprite.position = _recoil_offset()
	if _deco_anim != DecoAnim.NONE and _deco_sprite != null and _deco_sprite.visible:
		_apply_deco_animation(_deco_sprite, _time)
	if _atlas == null:
		_fallback_accum += delta
		if _fallback_accum >= FALLBACK_REDRAW:
			_fallback_accum = 0.0
			queue_redraw()
	if disabled:
		_overlay_accum += delta
		if _overlay_accum >= OVERLAY_REDRAW:
			_overlay_accum = 0.0
			if _overlay != null:
				_overlay.call("set_time", _time)
	if kick_timer <= 0.0 and _deco_anim == DecoAnim.NONE and not disabled and _atlas != null:
		set_process(false)


func _refresh_process() -> void:
	var needed := disabled or kick_timer > 0.0 or _atlas == null
	if not needed:
		needed = _deco_anim != DecoAnim.NONE
	set_process(needed)


## Animates a deco quad from the shared style curves. Only one or two sprite
## properties change per frame, so an animated tower stays as cheap as a
## static one while every style keeps its own unmistakable motion.
func _apply_deco_animation(sprite: Sprite2D, at_time: float) -> void:
	var rotation_value := _rotation_for(_deco_anim, _deco_rate, at_time)
	if rotation_value != 0.0:
		sprite.rotation = rotation_value
	var scale_value := _scale_for(_deco_anim, _deco_rate, at_time)
	if scale_value != 1.0:
		sprite.scale = _base_sprite_scale() * scale_value
	sprite.modulate.a = _alpha_for(_deco_anim, _deco_rate, at_time, _deco_flicker)


static func is_deco_animated(style_name: String) -> bool:
	return _anim_kind(style_name) != DecoAnim.NONE


static func _anim_kind(style_name: String) -> int:
	if DECO_SPIN.has(style_name):
		return DecoAnim.SPIN
	if DECO_PULSE.has(style_name):
		return DecoAnim.PULSE
	if DECO_SWEEP.has(style_name):
		return DecoAnim.SWEEP
	if DECO_CHARGE.has(style_name):
		return DecoAnim.CHARGE
	if DECO_BREATH.has(style_name):
		return DecoAnim.BREATH
	return DecoAnim.NONE


static func _anim_rate(style_name: String, kind: int) -> float:
	match kind:
		DecoAnim.SPIN:
			return float(DECO_SPIN[style_name])
		DecoAnim.PULSE:
			return float(DECO_PULSE[style_name])
		DecoAnim.SWEEP:
			return float(DECO_SWEEP[style_name])
		DecoAnim.CHARGE:
			return float(DECO_CHARGE[style_name])
		DecoAnim.BREATH:
			return float(DECO_BREATH[style_name])
	return 0.0


## Shared animation curves: the baked/live quad path and the vector fallback
## painter both use these, so the art can never drift apart.
static func deco_rotation(style_name: String, at_time: float) -> float:
	var kind := _anim_kind(style_name)
	return _rotation_for(kind, _anim_rate(style_name, kind), at_time)


static func deco_scale(style_name: String, at_time: float) -> float:
	var kind := _anim_kind(style_name)
	return _scale_for(kind, _anim_rate(style_name, kind), at_time)


static func deco_alpha(style_name: String, at_time: float) -> float:
	var kind := _anim_kind(style_name)
	return _alpha_for(kind, _anim_rate(style_name, kind), at_time,
		DECO_FLICKER.has(style_name))


static func _rotation_for(kind: int, rate: float, at_time: float) -> float:
	match kind:
		DecoAnim.SPIN:
			return at_time * rate
		DecoAnim.SWEEP:
			return sin(at_time * rate) * SWEEP_AMPLITUDE
	return 0.0


static func _scale_for(kind: int, rate: float, at_time: float) -> float:
	match kind:
		DecoAnim.CHARGE:
			return 0.8 + 0.45 * fmod(at_time * rate, 1.0)
		DecoAnim.BREATH:
			return 0.90 + 0.16 * (0.5 + 0.5 * sin(at_time * rate))
	return 1.0


static func _alpha_for(kind: int, rate: float, at_time: float, flicker: bool) -> float:
	match kind:
		DecoAnim.PULSE:
			var wave := 0.5 + 0.5 * sin(at_time * rate)
			if flicker:
				# Two detuned sines read as an irregular flame flicker.
				wave = 0.5 + 0.5 * (0.62 * sin(at_time * rate)
					+ 0.38 * sin(at_time * rate * 1.87 + 1.7))
			return 0.45 + 0.55 * wave
		DecoAnim.CHARGE:
			return 1.0 - 0.75 * fmod(at_time * rate, 1.0)
		DecoAnim.BREATH:
			return 0.45 + 0.55 * (0.5 + 0.5 * sin(at_time * rate))
	return 1.0


static func _base_sprite_scale() -> Vector2:
	return Vector2.ONE * (1.0 / BAKE_PIXELS_PER_UNIT)


## Finds the point in an alpha-pulse cycle where the deco layer is brightest, so
## the baked texture never caps the live dimming animation below its peak.
static func _bake_time_for(style_name: String) -> float:
	var kind := _anim_kind(style_name)
	var rate := _anim_rate(style_name, kind)
	if kind != DecoAnim.PULSE and kind != DecoAnim.BREATH:
		return 0.0
	var period := TAU / rate
	var best_time := 0.0
	var best_alpha := -1.0
	for step in 16:
		var at_time := period * float(step) / 16.0
		var alpha := _alpha_for(kind, rate, at_time, DECO_FLICKER.has(style_name))
		if alpha > best_alpha:
			best_alpha = alpha
			best_time = at_time
	return best_time




func _build_sprites() -> void:
	if _body_sprite != null:
		return
	_body_sprite = _make_sprite("Body")
	_deco_sprite = _make_sprite("Deco")
	_turret_sprite = _make_sprite("Turret")
	_overlay = Node2D.new()
	_overlay.name = "Overlay"
	_overlay.set_script(load("res://scripts/towers/TowerOverlay.gd"))
	add_child(_overlay)


func _make_sprite(sprite_name: String) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = sprite_name
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.scale = _base_sprite_scale()
	sprite.visible = false
	add_child(sprite)
	return sprite


func _apply_art() -> void:
	if _body_sprite == null:
		queue_redraw()
		return
	var atlas_ready := _atlas != null
	_apply_layer(_body_sprite, "body", atlas_ready)
	_apply_layer(_deco_sprite, "deco", atlas_ready)
	_apply_layer(_turret_sprite, "turret", atlas_ready)
	if _deco_sprite.visible:
		_apply_deco_animation(_deco_sprite, _time)
	_turret_sprite.rotation = aim
	_turret_sprite.position = _recoil_offset()
	_refresh_overlay()
	_refresh_process()
	# The relay aura (when present) lives in this item, behind the quads.
	queue_redraw()


func _apply_layer(sprite: Sprite2D, layer: String, atlas_ready: bool) -> void:
	var region: Variant = _regions.get(style + "/" + layer)
	if not atlas_ready or not _has_layer(style, layer) or not (region is Rect2):
		sprite.visible = false
		sprite.texture = null
		return
	sprite.texture = _atlas
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.visible = true


func _refresh_overlay() -> void:
	if _overlay == null:
		return
	var tower = get_parent()
	var tower_level := 1
	if tower != null and "current_level" in tower:
		tower_level = int(tower.current_level)
	var tower_max := 1
	var tower_color := Color(0.95, 0.64, 0.24)
	if data != null:
		tower_max = data.max_level
		tower_color = data.primary_color
	_overlay.call("set_state", selected, disabled, tower_level, tower_max, tower_color)


func _recoil_offset() -> Vector2:
	if kick_timer <= 0.0:
		return Vector2.ZERO
	return Vector2(-4.0 * minf(kick_timer / KICK_TIME, 1.0), 0.0).rotated(aim)


static func _has_layer(style_name: String, layer: String) -> bool:
	match layer:
		"deco":
			return is_deco_animated(style_name)
		"turret":
			return style_name != "tesla" and style_name != "relay" and style_name != "mine"
		_:
			return true


func _draw() -> void:
	if _bake_mode:
		match _bake_layer:
			"body":
				_paint_body(_bake_color)
			"deco":
				_paint_deco(_bake_color, _bake_time)
			_:
				_paint_turret(_bake_color)
		return
	if data == null:
		return
	var col := data.primary_color
	if style == "relay":
		_paint_relay_aura(col)
	if _atlas != null:
		return
	# Fallback until the atlas exists: paint the same layers immediately.
	_paint_body(col)
	_paint_deco(col, _time)
	draw_set_transform(_recoil_offset(), 0.0, Vector2.ONE)
	_paint_turret(col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _paint_body(col: Color) -> void:
	var metal := Color(0.19, 0.2, 0.23)
	var dark := Color(0.1, 0.11, 0.13)
	var light := Color(0.5, 0.52, 0.55)
	# Shadow and octagonal pad, shared by every style.
	draw_circle(Vector2(3, 7), 27, Color(0.0, 0.0, 0.0, 0.34))
	var pad := PackedVector2Array()
	for i in 8:
		var a := TAU * float(i) / 8.0 + PI / 8.0
		pad.append(Vector2(cos(a), sin(a)) * 28.0)
	draw_colored_polygon(pad, metal)
	var pad_line := pad.duplicate()
	pad_line.append(pad[0])
	draw_polyline(pad_line, Color(0.4, 0.34, 0.28), 2.0, true)
	draw_circle(Vector2.ZERO, 22, dark)

	match style:
		"relay":
			_draw_relay_body(col, light)
		"mine":
			_draw_mine_body(col, metal)
		"orbital":
			draw_circle(Vector2.ZERO, 19, Color(0.2, 0.17, 0.23))
		"flame":
			draw_circle(Vector2.ZERO, 19, Color(0.25, 0.2, 0.16))
			draw_circle(Vector2(-9, 8), 7, Color(0.38, 0.42, 0.2))
			draw_circle(Vector2(9, 8), 7, Color(0.38, 0.42, 0.2))
			draw_arc(Vector2.ZERO, 14, 0, TAU, 20, Color(1.0, 0.5, 0.13), 2.0, true)
		"tesla":
			draw_circle(Vector2.ZERO, 17, Color(0.16, 0.18, 0.22))
			for i in range(1, 4):
				draw_arc(Vector2.ZERO, 4.0 + i * 4.0, 0, TAU, 24, Color(0.35, 0.7, 1.0, 0.75), 2.0, true)
			draw_circle(Vector2(0, -22), 4, Color(0.8, 0.95, 1.0))
		"missile":
			draw_rect(Rect2(-17, -16, 34, 30), Color(0.25, 0.26, 0.24))
			for x in range(-13, 14, 9):
				for y in range(-12, 11, 8):
					draw_rect(Rect2(x, y, 6, 6), Color(0.14, 0.15, 0.16))
					draw_circle(Vector2(x + 3, y + 3), 1.5, col)
			# Visible missile tips above the cells.
			for i in 3:
				var off := Vector2(-11 + i * 11, -2)
				draw_circle(off, 3.2, Color(0.92, 0.78, 0.45))
				draw_line(off, off + Vector2(0, -7), Color(1.0, 0.55, 0.2), 2.0)
		"cryo":
			draw_circle(Vector2.ZERO, 18, Color(0.3, 0.42, 0.48))
			draw_circle(Vector2.ZERO, 13, Color(0.48, 0.68, 0.75))
			draw_circle(Vector2(0, -19), 5, Color(0.85, 0.98, 1.0))
		"rail":
			draw_circle(Vector2.ZERO, 15, Color(0.22, 0.24, 0.28))
			draw_circle(Vector2.ZERO, 10, col)
			draw_circle(Vector2(-2, -2), 4, Color(0.95, 0.98, 1.0))
			for i in 3:
				draw_circle(Vector2(-10 + i * 10, 18), 2.5, col)
		_:
			pass


func _paint_deco(col: Color, at_time: float) -> void:
	match style:
		"pulse":
			# Twin power coils that breathe in place around the base.
			var breath := deco_scale(style, at_time)
			var glow := deco_alpha(style, at_time)
			if not _bake_mode:
				draw_set_transform(Vector2.ZERO, 0.0, Vector2(breath, breath))
			for i in 2:
				var coil := Vector2(-20.0 if i == 0 else 20.0, 7.0)
				draw_circle(coil, 5.5, Color(col.r, col.g, col.b, 0.3 * glow))
				draw_arc(coil, 7.5, 0, TAU, 16, Color(col.r, col.g, col.b, 0.85 * glow), 1.6, true)
			draw_arc(Vector2.ZERO, 24.0, 0, TAU, 30, Color(col.r, col.g, col.b, 0.28 * glow), 1.5, true)
			if not _bake_mode:
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"cannon":
			# Slow autoloader carousel feeding the siege gun.
			if not _bake_mode:
				draw_set_transform(Vector2.ZERO, deco_rotation(style, at_time), Vector2.ONE)
			for i in 3:
				var a := TAU * float(i) / 3.0
				var dir := Vector2(cos(a), sin(a))
				draw_line(dir * 9.0, dir * 20.0, Color(0.4, 0.36, 0.3), 3.0, true)
				draw_circle(dir * 20.0, 4.0, Color(0.94, 0.8, 0.46))
				draw_circle(dir * 20.0, 1.8, Color(0.45, 0.32, 0.15))
			if not _bake_mode:
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"flame":
			# Pilot flames in the exhaust vents, flickering irregularly.
			var flicker := deco_alpha(style, at_time)
			for i in 2:
				var x := -13.0 + float(i) * 26.0
				draw_circle(Vector2(x, 14), 5.5, Color(1.0, 0.42, 0.1, 0.85 * flicker))
				draw_circle(Vector2(x, 13), 2.8, Color(1.0, 0.87, 0.4, flicker))
		"missile":
			# Targeting radar mast sweeping back and forth over the rack.
			if not _bake_mode:
				draw_set_transform(Vector2.ZERO, deco_rotation(style, at_time), Vector2.ONE)
			draw_line(Vector2.ZERO, Vector2(20, 0), Color(col.r, col.g, col.b, 0.55), 1.5, true)
			draw_arc(Vector2.ZERO, 23.0, -0.45, 0.45, 14, Color(col.r, col.g, col.b, 0.85), 2.2, true)
			draw_circle(Vector2(23, 0), 2.5, Color(1.0, 0.9, 0.7))
			if not _bake_mode:
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"rail":
			# Capacitor rings charging outward before the shot.
			var charge := deco_scale(style, at_time)
			var energised := deco_alpha(style, at_time)
			if not _bake_mode:
				draw_set_transform(Vector2.ZERO, 0.0, Vector2(charge, charge))
			draw_arc(Vector2.ZERO, 22.0, 0, TAU, 30, Color(col.r, col.g, col.b, 0.6 * energised), 2.0, true)
			draw_arc(Vector2.ZERO, 28.0, 0, TAU, 34, Color(0.75, 0.9, 1.0, 0.4 * energised), 1.4, true)
			for i in 4:
				var a := TAU * float(i) / 4.0 + PI / 4.0
				draw_circle(Vector2(cos(a), sin(a)) * 15.0, 2.0, Color(0.8, 0.9, 1.0, 0.55 + 0.45 * energised))
			if not _bake_mode:
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"tesla":
			for i in 4:
				var a := at_time * 1.8 + TAU * float(i) / 4.0
				var p := Vector2(cos(a), sin(a)) * 22.0
				draw_circle(p, 3.0, Color(0.6, 0.9, 1.0))
				draw_line(p, Vector2(cos(a + 0.4), sin(a + 0.4)) * 14.0, Color(0.4, 0.8, 1.0, 0.65), 1.5, true)
		"cryo":
			for i in 6:
				var a := TAU * float(i) / 6.0 + at_time * 0.35
				draw_line(Vector2(cos(a), sin(a)) * 8, Vector2(cos(a), sin(a)) * 23, Color(0.75, 0.95, 1.0, 0.9), 2.0, true)
		"orbital":
			draw_arc(Vector2.ZERO, 24.0, -at_time * 1.5, -at_time * 1.5 + 3.5, 28, col, 2.0, true)
		"relay":
			var pulse := 0.5 + 0.5 * sin(at_time * 3.0)
			draw_circle(Vector2(0, -25), 4.5, Color(col.r, col.g, col.b, 0.5 + 0.5 * pulse))
		"mine":
			var pulse := 0.5 + 0.5 * sin(at_time * 5.0)
			draw_circle(Vector2(0, 14), 3.0, Color(1.0, 0.35, 0.15, 0.5 + pulse * 0.5))
		_:
			pass


func _paint_turret(col: Color) -> void:
	var metal := Color(0.19, 0.2, 0.23)
	var light := Color(0.5, 0.52, 0.55)
	var dir := Vector2.RIGHT.rotated(aim)
	var side := dir.orthogonal()
	match style:
		"pulse":
			draw_line(Vector2.ZERO, dir * 27.0, Color(0.35, 0.37, 0.4), 8.0, true)
			draw_line(dir * 4 + side * 4.0, dir * 27 + side * 4.0, col, 3.0, true)
			draw_line(dir * 4 - side * 4.0, dir * 27 - side * 4.0, col, 3.0, true)
			draw_circle(Vector2.ZERO, 13, metal)
			draw_circle(Vector2.ZERO, 8, Color(col.r * 0.5, col.g * 0.5, col.b * 0.5))
			draw_circle(Vector2(0, -1), 4, col)
		"cannon":
			draw_line(Vector2.ZERO, dir * 31.0, Color(0.32, 0.33, 0.36), 13.0, true)
			draw_line(Vector2.ZERO, dir * 31.0, Color(0.52, 0.44, 0.32), 8.0, true)
			draw_circle(Vector2.ZERO, 18, metal)
			draw_circle(Vector2.ZERO, 13, Color(0.29, 0.28, 0.26))
			draw_arc(Vector2.ZERO, 13, 0, TAU, 20, col, 2.5, true)
			draw_rect(Rect2(-9, -14, 7, 5), light)
			draw_rect(Rect2(-9, -8, 7, 5), light)
		"flame":
			for i in range(-2, 3):
				var a := aim - 0.32 + float(i) * 0.16
				var d := Vector2.RIGHT.rotated(a)
				# The body circle (radius 19) sits in the baked base layer, so the
				# nozzle stubs start at its edge instead of the centre.
				draw_line(d * 18.0, d * 26.0, Color(0.35, 0.18, 0.12), 5.0, true)
				draw_line(d * 18.0, d * 29.0, Color(1.0, 0.45, 0.12), 6.0, true)
		"missile":
			draw_line(Vector2.ZERO, dir * 26, Color(0.55, 0.55, 0.5), 3.0, true)
		"cryo":
			draw_line(dir * 12, dir * 25, Color(0.8, 0.97, 1.0), 5.0, true)
		"rail":
			var rail_line := Color(0.65, 0.7, 0.73)
			draw_line(dir * 14.0, dir * 35.0, rail_line, 6.0, true)
			draw_line(dir * 31 + side * 6, dir * 38 + side * 6, Color(0.35, 0.38, 0.42), 2.0, true)
			draw_line(dir * 31 - side * 6, dir * 38 - side * 6, Color(0.35, 0.38, 0.42), 2.0, true)
		"orbital":
			draw_line(Vector2.ZERO, dir * 18.0, light, 4.0, true)
			# Parabolic dish.
			var dish_center := dir * 15.0
			for i in 3:
				draw_arc(dish_center, 9.0 + i * 4.0, aim - 0.9, aim + 0.9, 14, Color(col.r, col.g, col.b, 0.9 - i * 0.22), 2.0, true)
			draw_circle(dish_center, 10.0, Color(col.r, col.g, col.b, 0.2))
			draw_circle(dish_center, 4.0, Color(1.0, 0.8, 0.9))
		_:
			pass


func _paint_relay_aura(col: Color) -> void:
	var parent_tower = get_parent()
	var aura: float = float(parent_tower.stats.get("support_radius", 0.0)) if parent_tower and "stats" in parent_tower else 0.0
	if aura <= 0.0:
		return
	draw_circle(Vector2.ZERO, aura, Color(col.r, col.g, col.b, 0.045))
	draw_arc(Vector2.ZERO, aura, 0, TAU, 64, Color(col.r, col.g, col.b, 0.28), 1.5, true)
	draw_arc(Vector2.ZERO, aura * 0.7, 0.0, 4.0, 24, Color(col.r, col.g, col.b, 0.4), 2.0, true)


func _draw_relay_body(col: Color, light: Color) -> void:
	draw_circle(Vector2.ZERO, 17, Color(0.18, 0.21, 0.2))
	draw_circle(Vector2.ZERO, 11, Color(0.25, 0.32, 0.28))
	draw_line(Vector2(0, 4), Vector2(0, -22), light, 3.0, true)
	for i in 3:
		var y := -8.0 - i * 6.0
		draw_arc(Vector2(0, y + 5), 7.0 + i * 4.0, PI + 0.5, TAU - 0.5, 12, col, 1.6, true)
	draw_circle(Vector2(-14, 13), 3, col)
	draw_circle(Vector2(14, 13), 3, col)


func _draw_mine_body(col: Color, metal: Color) -> void:
	draw_rect(Rect2(-20, -14, 40, 28), metal)
	draw_rect(Rect2(-15, -9, 30, 18), Color(0.22, 0.2, 0.17))
	for i in 3:
		draw_rect(Rect2(-13 + i * 10, -6, 7, 7), Color(0.08, 0.08, 0.09))
		draw_circle(Vector2(-9.5 + i * 10, -2.5), 2.0, col)


## Renders every tower style into one shared atlas. Called once per session by
## LevelBase; safe to call again after the atlas already exists.
static func bake_atlas(host: Node, data_list: Array) -> void:
	if _atlas != null or host == null:
		return
	if DisplayServer.get_name() == "headless":
		# No real renderer: install a blank atlas so live towers keep the cheap
		# quad path instead of rebuilding vector art every frame.
		_install_blank_atlas()
		_refresh_live_towers(host)
		return

	var tints := {}
	for tower_data in data_list:
		if tower_data != null and tower_data is TowerData:
			tints[String(tower_data.visual_style)] = tower_data.primary_color

	var viewport := SubViewport.new()
	viewport.name = "TowerArtAtlas"
	viewport.size = Vector2i(BAKE_CELL_PIXELS * LAYERS.size(), BAKE_CELL_PIXELS * STYLES.size())
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.msaa_2d = Viewport.MSAA_DISABLED
	host.add_child(viewport)

	var painter_script := load("res://scripts/towers/TowerVisual.gd")
	for row in STYLES.size():
		var style_name: String = STYLES[row]
		var tint: Color = tints.get(style_name, Color(0.85, 0.62, 0.3))
		# Bake the deco layer at its brightest so the live quad can only dim it.
		var paint_time := _bake_time_for(style_name)
		for column in LAYERS.size():
			var holder := Node2D.new()
			holder.position = Vector2(
				(float(column) + 0.5) * float(BAKE_CELL_PIXELS),
				(float(row) + 0.5) * float(BAKE_CELL_PIXELS))
			holder.scale = Vector2.ONE * BAKE_PIXELS_PER_UNIT
			viewport.add_child(holder)
			var painter := Node2D.new()
			painter.set_script(painter_script)
			painter.set("_bake_mode", true)
			painter.set("style", style_name)
			painter.set("_bake_layer", LAYERS[column])
			painter.set("_bake_color", tint)
			painter.set("_bake_time", paint_time)
			holder.add_child(painter)

	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	var image: Image = null
	var texture := viewport.get_texture()
	if texture != null:
		image = texture.get_image()
	viewport.queue_free()

	if image == null:
		_install_blank_atlas()
		_refresh_live_towers(host)
		return

	_atlas = ImageTexture.create_from_image(image)
	for row in STYLES.size():
		for column in LAYERS.size():
			_regions[STYLES[row] + "/" + LAYERS[column]] = Rect2(
				Vector2(float(column) * float(BAKE_CELL_PIXELS), float(row) * float(BAKE_CELL_PIXELS)),
				Vector2(float(BAKE_CELL_PIXELS), float(BAKE_CELL_PIXELS)))
	_refresh_live_towers(host)


static func _install_blank_atlas() -> void:
	var blank := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	blank.fill(Color(0, 0, 0, 0))
	_atlas = ImageTexture.create_from_image(blank)
	for style_name in STYLES:
		for layer in LAYERS:
			_regions[style_name + "/" + layer] = Rect2(0, 0, 4, 4)


static func _refresh_live_towers(host: Node) -> void:
	if host == null or not host.is_inside_tree():
		return
	for tower in host.get_tree().get_nodes_in_group("towers"):
		var visual = tower.get_node_or_null("Visual")
		if visual != null and visual.has_method("refresh_art"):
			visual.call("refresh_art")
