extends Node

## sfx_jump.wav is jump_air_opt1, Thong's pick.
const STREAMS := {
	"jump": preload("res://assets/audio/sfx_jump.wav"),
	"dash": preload("res://assets/audio/sfx_dash.wav"),
	"attack": preload("res://assets/audio/sfx_pirate_attack.wav"),
	"kill": preload("res://assets/audio/sfx_kill.wav"),
	"death": preload("res://assets/audio/sfx_death.wav"),
	"warning": preload("res://assets/audio/sfx_tear_warning.wav"),
}

var _players: Array[AudioStreamPlayer] = []
var _next: int = 0
var _last_ms: Dictionary = {}
var _chime: AudioStreamWAV
## Empty on purpose. Drop the Overdrive punch SFX on this player later.
var overdrive_punch: AudioStreamPlayer


func _ready() -> void:
	overdrive_punch = AudioStreamPlayer.new()
	overdrive_punch.name = "overdrive_punch"
	add_child(overdrive_punch)
	_chime = _make_chime()
	for _i in 12:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)


func play_overdrive_punch() -> void:
	if overdrive_punch == null or overdrive_punch.stream == null:
		return
	overdrive_punch.play()


func play(id: String, pitch_shift: float = 0.0, volume_db: float = 0.0) -> void:
	var stream: AudioStream = _chime if id == "chime" else STREAMS.get(id)
	if stream == null:
		return
	var now := Time.get_ticks_msec()
	var previous := int(_last_ms.get(id, -10000))
	var stacked := now - previous < 90
	_last_ms[id] = now
	if stacked and (id == "death" or id == "warning" or id == "dash"):
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
