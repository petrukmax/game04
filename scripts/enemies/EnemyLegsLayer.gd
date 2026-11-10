extends Node2D
## Draws every arachnid's legs in one batched canvas item.
## Each enemy used to own a Legs node that rebuilt 3 multiline commands at
## 30 Hz. At 140 enemies that was 420 canvas items re-recording every frame.
## Here one node rebuilds, and legs are merged per colour: ~18 draw commands
## for the whole swarm.

const REDRAW_INTERVAL := 1.0 / 30.0

var _time: float = 0.0
var _accum: float = 0.0


func _process(delta: float) -> void:
	_accum += delta
	if _accum < REDRAW_INTERVAL:
		return
	_accum = 0.0
	_time += delta
	queue_redraw()


func _draw() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return
	# colour -> flat point list, grouped by leg segment type.
	var upper: Dictionary = {}
	var lower: Dictionary = {}
	var knees: Dictionary = {}
	var layer_transform := global_transform.affine_inverse()
	for enemy in enemies:
		if enemy == null or not is_instance_valid(enemy):
			continue
		if enemy.dead or enemy.removed or enemy.burrow_active:
			continue
		var visual = enemy.get_node_or_null("Visual")
		if visual == null or not visual.visible:
			continue
		var base: Color = visual.body_color
		var moving: bool = visual.moving
		var stunned: bool = visual.stunned
		var xf: Transform2D = layer_transform * visual.global_transform
		var limb := base.darkened(0.25)
		var joint := base.lightened(0.18)
		var upper_points: PackedVector2Array = upper.get(limb, PackedVector2Array())
		var lower_points: PackedVector2Array = lower.get(limb, PackedVector2Array())
		var knee_points: PackedVector2Array = knees.get(joint, PackedVector2Array())
		# Deterministic per-enemy phase offset keeps the swarm from marching in lockstep.
		var phase_offset := float(enemy.get_instance_id() % 1000) * 0.013
		for side in [-1.0, 1.0]:
			for i in 4:
				var phase := _time * 9.0 + float(i) * 1.3 + phase_offset + (0.0 if side > 0.0 else PI)
				var swing := sin(phase) * 3.5 if moving and not stunned else 0.0
				var base_x := -12.0 + float(i) * 7.5
				var hip := xf * Vector2(base_x, side * 5.0)
				var knee := xf * Vector2(base_x + swing, side * (12.0 + float(i % 2) * 3.0))
				var foot := xf * Vector2(base_x + swing * 1.7 + 3.0, side * (24.0 + float(i % 2) * 4.0))
				upper_points.append(hip)
				upper_points.append(knee)
				lower_points.append(knee)
				lower_points.append(foot)
				knee_points.append(xf * (Vector2(base_x + swing, side * (12.0 + float(i % 2) * 3.0)) + Vector2(-0.9, 0.0)))
				knee_points.append(xf * (Vector2(base_x + swing, side * (12.0 + float(i % 2) * 3.0)) + Vector2(0.9, 0.0)))
		upper[limb] = upper_points
		lower[limb] = lower_points
		knees[joint] = knee_points
	for colour in upper:
		draw_multiline(upper[colour], colour, 3.4, false)
	for colour in lower:
		draw_multiline(lower[colour], Color(colour).lightened(0.12), 2.0, false)
	for colour in knees:
		draw_multiline(knees[colour], colour, 2.2, false)
