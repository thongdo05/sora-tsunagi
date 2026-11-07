extends Node

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


func _ready() -> void:
	for _i in 10:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)


func play(id: String, pitch_shift: float = 0.0, volume_db: float = 0.0) -> void:
	if not STREAMS.has(id):
		return
	var now := Time.get_ticks_msec()
	var previous := int(_last_ms.get(id, -10000))
	var stacked := now - previous < 90
	_last_ms[id] = now
	if stacked and (id == "death" or id == "warning" or id == "dash"):
		return
	var player := _players[_next]
	_next = (_next + 1) % _players.size()
	player.stream = STREAMS[id]
	var extra_pitch := 0.07 if stacked else 0.0
	var extra_db := -8.0 if stacked else 0.0
	player.pitch_scale = clampf(1.0 + pitch_shift + extra_pitch + randf_range(-0.035, 0.035), 0.72, 1.45)
	player.volume_db = volume_db + extra_db
	player.play()
