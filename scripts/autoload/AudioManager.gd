extends Node
## Pooled procedural SFX + ambience. Never lets delayed frames build a sound backlog.

const SOUND_NAMES: Array[String] = [
	"ui_click", "ui_hover", "ui_confirm", "ui_error", "ui_cancel",
	"build", "upgrade", "sell",
	"shot_kinetic", "shot_cannon", "shot_flame", "shot_tesla", "shot_missile",
	"shot_frost", "shot_rail", "support_pulse", "mine_deploy", "orbital_charge", "orbital_impact",
	"enemy_spawn", "enemy_hit", "enemy_death", "shield_break", "burrow", "emerge", "boss_roar",
	"base_damage", "wave_start", "wave_complete", "victory", "defeat",
	"ability_emp", "ability_strike", "ability_repair", "ability_supply", "drone_shot",
]

const POOL_SIZE := 18
const SAME_SOUND_COOLDOWN_MS := 45

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next_player: int = 0
var _last_played: Dictionary = {}
var _ambience: AudioStreamPlayer
var _master: float = 0.8
var _sfx: float = 0.85
var _music: float = 0.5
var _muted: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for sound_name in SOUND_NAMES:
		var path := "res://assets/audio/%s.wav" % sound_name
		if ResourceLoader.exists(path):
			var stream: Resource = load(path)
			if stream is AudioStream:
				_streams[sound_name] = stream
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.name = "SfxPlayer%d" % i
		add_child(player)
		_players.append(player)
	_ambience = AudioStreamPlayer.new()
	_ambience.name = "MarsAmbience"
	add_child(_ambience)
	_ambience.finished.connect(_loop_ambience)
	if ResourceLoader.exists("res://assets/audio/ambient_mars.wav"):
		_ambience.stream = load("res://assets/audio/ambient_mars.wav")


func refresh_from_settings(settings: Dictionary) -> void:
	_master = clampf(float(settings.get("master_volume", 0.8)), 0.0, 1.0)
	_sfx = clampf(float(settings.get("sfx_volume", 0.85)), 0.0, 1.0)
	_music = clampf(float(settings.get("music_volume", 0.5)), 0.0, 1.0)
	_muted = GameConfig.as_bool(settings.get("muted", false))
	if _ambience and _ambience.playing:
		_ambience.volume_db = _music_db()
	if _muted:
		stop_all_sfx()


func _music_db() -> float:
	if _muted or _music <= 0.001 or _master <= 0.001:
		return -80.0
	return linear_to_db(clampf(_master * _music * 0.7, 0.0001, 1.0))


func _sfx_db(volume: float) -> float:
	if _muted or _sfx <= 0.001 or _master <= 0.001:
		return -80.0
	return linear_to_db(clampf(_master * _sfx * volume, 0.0001, 1.0))


func play_sound(sound_name: String, volume: float = 1.0, pitch: float = 1.0) -> void:
	if _muted or not _streams.has(sound_name):
		return
	var now := Time.get_ticks_msec()
	var last := int(_last_played.get(sound_name, -1000))
	if now - last < SAME_SOUND_COOLDOWN_MS:
		return
	_last_played[sound_name] = now
	var player := _get_player()
	if player == null:
		return
	player.stream = _streams[sound_name]
	player.volume_db = _sfx_db(volume)
	player.pitch_scale = clampf(pitch, 0.55, 1.8)
	player.play()


func play_ui(sound_name: String = "ui_click") -> void:
	play_sound(sound_name, 0.55, 1.0)


func _get_player() -> AudioStreamPlayer:
	if _players.is_empty():
		return null
	for offset in POOL_SIZE:
		var index := (_next_player + offset) % POOL_SIZE
		if not _players[index].playing:
			_next_player = (index + 1) % POOL_SIZE
			return _players[index]
	var fallback := _players[_next_player]
	_next_player = (_next_player + 1) % POOL_SIZE
	return fallback


func start_ambience() -> void:
	if _ambience == null or _ambience.stream == null:
		return
	if _ambience.playing:
		_ambience.volume_db = _music_db()
		return
	_ambience.volume_db = _music_db()
	_ambience.play()


func stop_ambience() -> void:
	if _ambience:
		_ambience.stop()


func _loop_ambience() -> void:
	if _ambience and _ambience.stream and not _muted:
		_ambience.volume_db = _music_db()
		_ambience.play()


func stop_all_sfx() -> void:
	for player in _players:
		player.stop()


func set_muted(muted: bool) -> void:
	# Callers persist the "muted" setting first. Do not re-read the settings
	# dictionary here, or a stale value would immediately override this change.
	_muted = muted
	if _muted:
		stop_all_sfx()
		stop_ambience()
	else:
		start_ambience()
