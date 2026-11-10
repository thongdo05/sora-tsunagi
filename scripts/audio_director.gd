extends Node

## sfx_jump.wav is jump_air_opt1, Thong's pick.
const DASH_PUNCH := preload("res://audio/final/punch/sfx_pirate_dash_punch.wav")
const OVERDRIVE_PUNCH := preload("res://audio/final/punch/sfx_pirate_overdrive_punch.wav")
## Where the hit sits inside each file. The punch clock subtracts this from cell 6.
const DASH_PUNCH_TRANSIENT_MS := 68
const OVERDRIVE_PUNCH_TRANSIENT_MS := 4
## Whole file, already cut on the bar. Loop from the start, no offset.
const THEME := preload("res://audio/music/Glassfall_Theme_JP_Instrumental_172bpm_loop.ogg")
const MUSIC_BUS := "Music"
## SFX stay on Master at 0 dB. This bus sits under them.
const MUSIC_BUS_DB := -6.0

const STREAMS := {
	"jump": preload("res://assets/audio/sfx_jump.wav"),
	"dash": preload("res://assets/audio/sfx_dash.wav"),
	"attack": preload("res://assets/audio/sfx_pirate_attack.wav"),
	"kill": preload("res://assets/audio/sfx_kill.wav"),
	"death": preload("res://assets/audio/sfx_death.wav"),
	"warning": preload("res://assets/audio/sfx_tear_warning.wav"),
	"hound_growl": preload("res://audio/final/enemies/sfx_void_hound_growl.wav"),
	"hound_shatter": preload("res://audio/final/enemies/sfx_void_hound_shatter.wav"),
	"wisp_shatter": preload("res://audio/final/enemies/sfx_lantern_wisp_shatter.wav"),
}

var _players: Array[AudioStreamPlayer] = []
var _next: int = 0
var _last_ms: Dictionary = {}
var _chime: AudioStreamWAV
## Overdrive impact. Stream is Thong's final punch. It does not loop.
var overdrive_punch: AudioStreamPlayer
var dash_punch: AudioStreamPlayer
var _music: AudioStreamPlayer
var _fade: Tween
var _fade_token: int = 0
var _music_wanted: bool = false
var _arm_gesture: bool = false


func _ready() -> void:
	_ensure_music_bus()
	var theme := THEME.duplicate() as AudioStreamOggVorbis
	theme.loop = true
	theme.loop_offset = 0.0
	_music = AudioStreamPlayer.new()
	_music.name = "music"
	_music.stream = theme
	_music.bus = MUSIC_BUS
	_music.volume_db = 0.0
	# Hit-stop pauses the tree. The theme keeps going.
	_music.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_music)
	_silence_loop(DASH_PUNCH)
	_silence_loop(OVERDRIVE_PUNCH)
	dash_punch = AudioStreamPlayer.new()
	dash_punch.name = "dash_punch"
	dash_punch.stream = DASH_PUNCH
	add_child(dash_punch)
	overdrive_punch = AudioStreamPlayer.new()
	overdrive_punch.name = "overdrive_punch"
	overdrive_punch.stream = OVERDRIVE_PUNCH
	add_child(overdrive_punch)
	_chime = _make_chime()
	for _i in 12:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)


func dash_punch_transient_ms() -> int:
	return DASH_PUNCH_TRANSIENT_MS


func overdrive_punch_transient_ms() -> int:
	return OVERDRIVE_PUNCH_TRANSIENT_MS


func _process(_delta: float) -> void:
	if _music == null or not _music.playing:
		return
	# Death slow-mo would otherwise drop the song with the gameplay clock.
	var scale := maxf(Engine.time_scale, 0.05)
	_music.pitch_scale = clampf(1.0 / scale, 0.25, 8.0)


func start_music() -> void:
	_music_wanted = true
	_play_from_start()
	if OS.has_feature("web") and (_music == null or not _music.playing):
		_arm_gesture = true
		call_deferred("_retry_music")


func fade_music() -> void:
	_music_wanted = false
	_arm_gesture = false
	if _music == null or not _music.playing:
		return
	_fade_token += 1
	var token := _fade_token
	_kill_fade()
	_fade = create_tween()
	_fade.set_ignore_time_scale(true)
	_fade.tween_property(_music, "volume_db", -40.0, 0.5)
	_fade.tween_callback(func() -> void:
		if token != _fade_token or _music == null:
			return
		_music.stop()
	)


func _retry_music() -> void:
	if _music_wanted and _music != null and not _music.playing:
		_play_from_start()
		_arm_gesture = OS.has_feature("web") and not _music.playing


func _input(event: InputEvent) -> void:
	if not _arm_gesture or not _music_wanted:
		return
	if not _is_press(event):
		return
	_arm_gesture = false
	_play_from_start()


func _play_from_start() -> void:
	if _music == null:
		return
	_fade_token += 1
	_kill_fade()
	_music.pitch_scale = 1.0
	_music.volume_db = 0.0
	_music.play(0.0)


func _kill_fade() -> void:
	if _fade != null and _fade.is_valid():
		_fade.kill()
	_fade = null


func _ensure_music_bus() -> void:
	var idx := AudioServer.get_bus_index(MUSIC_BUS)
	if idx < 0:
		AudioServer.add_bus()
		idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, MUSIC_BUS)
		AudioServer.set_bus_send(idx, "Master")
	AudioServer.set_bus_volume_db(idx, MUSIC_BUS_DB)


func _is_press(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return (event as InputEventMouseButton).pressed
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).pressed
	if event is InputEventKey:
		return (event as InputEventKey).pressed
	return false


func play_dash_punch() -> void:
	_play_once(dash_punch)


func play_overdrive_punch() -> void:
	_play_once(overdrive_punch)


func cancel_punch_sounds() -> void:
	if dash_punch != null and dash_punch.playing:
		dash_punch.stop()
	if overdrive_punch != null and overdrive_punch.playing:
		overdrive_punch.stop()


func _play_once(player: AudioStreamPlayer) -> void:
	if player == null or player.stream == null:
		return
	player.stop()
	player.play()


func _silence_loop(stream: AudioStream) -> void:
	if stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_DISABLED


func play(id: String, pitch_shift: float = 0.0, volume_db: float = 0.0) -> void:
	var stream: AudioStream = _chime if id == "chime" else STREAMS.get(id)
	if stream == null:
		return
	var now := Time.get_ticks_msec()
	var previous := int(_last_ms.get(id, -10000))
	var stacked := now - previous < 90
	_last_ms[id] = now
	if stacked and (id == "death" or id == "warning" or id == "dash" or id == "hound_growl"):
		return
	var player := _players[_next]
	_next = (_next + 1) % _players.size()
	player.stream = stream
	# Jump and the sliver chime own their pitch. A little random keeps repeats from locking in.
	var jitter := 0.03
	if id == "jump":
		jitter = 0.055
	elif id == "chime":
		jitter = 0.012
	var extra_pitch := 0.0
	var extra_db := 0.0
	if stacked and id != "jump" and id != "chime":
		extra_pitch = 0.07
		extra_db = -8.0
	player.pitch_scale = clampf(1.0 + pitch_shift + extra_pitch + randf_range(-jitter, jitter), 0.72, 1.7)
	player.volume_db = volume_db + extra_db
	player.play()


## Bright short bell. Hibiki replaces this. The streak pitch is applied by the caller.
func _make_chime() -> AudioStreamWAV:
	var rate := 44100
	var seconds := 0.16
	var count := int(rate * seconds)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var tones := [1568.0, 2093.0, 3136.0]
	var weights := [0.62, 0.3, 0.12]
	for i in count:
		var t := float(i) / float(rate)
		var env := exp(-t * 28.0) * clampf(t / 0.004, 0.0, 1.0)
		var sample := 0.0
		for n in tones.size():
			sample += sin(TAU * tones[n] * t) * weights[n]
		var value := int(clampf(sample * env * 0.42, -1.0, 1.0) * 32767.0)
		bytes[i * 2] = value & 255
		bytes[i * 2 + 1] = (value >> 8) & 255
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = bytes
	return stream
