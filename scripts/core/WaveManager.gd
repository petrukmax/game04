class_name WaveManager
extends Node
## Deterministic wave scheduling, concurrent early calls and completion detection.

var level: Node
var level_data: LevelData
var total_waves: int = 0
var started_waves: int = 0
var finished_waves: int = 0
var enemies_alive: int = 0
var spawn_queue: Array = []
var elapsed: float = 0.0
var wave_victory: bool = false
var early_calls: int = 0


func setup(owner_level: Node, data: LevelData) -> void:
	level = owner_level
	level_data = data
	total_waves = data.wave_data_list.size()
	started_waves = 0
	finished_waves = 0
	enemies_alive = 0
	spawn_queue.clear()
	elapsed = 0.0
	wave_victory = false
	early_calls = 0


func tick(delta: float) -> void:
	if wave_victory:
		return
	elapsed += delta
	while not spawn_queue.is_empty() and float(spawn_queue[0].time) <= elapsed:
		var task: Dictionary = spawn_queue.pop_front()
		if level.call("spawn_enemy", String(task.enemy_id), int(task.path)):
			enemies_alive += 1
	_check_completion()


func on_enemy_removed() -> void:
	enemies_alive = maxi(0, enemies_alive - 1)
	_check_completion()


func start_next_wave() -> bool:
	if started_waves >= total_waves or wave_victory:
		return false
	var wave: WaveData = level_data.wave_data_list[started_waves]
	var was_active := has_active_wave()
	var tasks: Array = []
	for entry in wave.entries:
		if entry == null:
			continue
		for i in int(entry.count):
			tasks.append({
				"time": elapsed + float(entry.delay) + float(i) * float(entry.interval),
				"enemy_id": entry.enemy_id,
				"path": int(entry.path),
			})
	tasks.sort_custom(func(a, b): return float(a.time) < float(b.time))
	spawn_queue.append_array(tasks)
	spawn_queue.sort_custom(func(a, b): return float(a.time) < float(b.time))
	started_waves += 1
	if was_active:
		early_calls += 1
		var bonus := 20 + 5 * started_waves
		level.economy.add_credits(bonus, "early call")
		EventBus.notification.emit("Early call: +%d credits" % bonus, GameConfig.AMBER)
	EventBus.wave_started.emit(started_waves, total_waves, wave.preview)
	EventBus.notification.emit("Wave %d incoming — %s" % [started_waves, wave.preview], GameConfig.OFFWHITE)
	if level.has_method("on_wave_started"):
		level.on_wave_started(started_waves, total_waves, wave)
	return true


func _check_completion() -> void:
	if spawn_queue.is_empty() and enemies_alive <= 0 and started_waves > finished_waves:
		var newly_finished := started_waves - finished_waves
		var total_bonus := 0
		for i in newly_finished:
			var index := finished_waves + i
			if index < level_data.wave_data_list.size():
				var wave: WaveData = level_data.wave_data_list[index]
				total_bonus += wave.completion_bonus
				finished_waves += 1
				EventBus.wave_completed.emit(finished_waves, wave.completion_bonus)
		level.economy.add_credits(total_bonus, "wave")
		EventBus.notification.emit("Wave cleared. +%d credits" % total_bonus, GameConfig.AMBER)
		if level.has_method("on_wave_cleared"):
			level.on_wave_cleared(finished_waves, total_bonus)
		if finished_waves >= total_waves:
			wave_victory = true
			EventBus.all_waves_completed.emit()
			if level.has_method("on_all_waves_cleared"):
				level.on_all_waves_cleared()


func has_active_wave() -> bool:
	return started_waves > finished_waves


func all_waves_started() -> bool:
	return started_waves >= total_waves


func can_call_early() -> bool:
	return started_waves < total_waves and has_active_wave()


func next_wave_data() -> WaveData:
	if started_waves < total_waves:
		return level_data.wave_data_list[started_waves]
	return null


func current_number() -> int:
	return clampi(started_waves if started_waves > 0 else 1, 1, total_waves)


func progress_text() -> String:
	return "Wave %d / %d" % [current_number(), total_waves]


func next_preview() -> String:
	var wave := next_wave_data()
	if wave == null:
		return "Final wave in progress"
	return wave.preview
