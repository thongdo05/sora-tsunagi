class_name GameTuning
extends Resource

## Every gameplay number for the Glassfall prototype lives here.
## Edit this resource (game_tuning.tres) and run again. Units are pixels and seconds.
## Jump height is jump_velocity^2 / (2 * gravity). Dash length is dash_distance
## (the distance covered during dash_duration; the burst never goes slower than the run).

@export_group("Run")
@export var run_speed_start: float = 580.0
@export var run_speed_max: float = 1040.0
## Pixels per second added to run speed each second, until run_speed_max.
@export var run_acceleration: float = 6.5

@export_group("Jump")
@export var gravity: float = 2500.0
@export var jump_velocity: float = -1000.0
@export var double_jump_velocity: float = -860.0
@export var glide_gravity: float = 480.0
@export var glide_max_fall: float = 140.0
@export var max_fall_speed: float = 1500.0
@export var coyote_time: float = 0.12
@export var jump_buffer: float = 0.14

@export_group("Dash")
@export var dash_distance: float = 280.0
@export var dash_duration: float = 0.16
@export var dash_cooldown: float = 0.52
@export var dash_buffer: float = 0.12
## Gravity multiplier while the dash is active, so the strike doesn't drop out.
@export var dash_gravity_scale: float = 0.45
## Upward kick applied if a platform lip stops the run, so the body doesn't stick.
@export var lip_hop_velocity: float = -380.0

@export_group("Feel")
@export var hit_stop_ms: int = 70
@export var hit_stop_time_scale: float = 0.02
@export var shake_strength: float = 13.0
@export var shake_duration: float = 0.22
@export var hurt_invuln: float = 1.4
@export var respawn_delay: float = 0.45
@export var kill_margin: float = 90.0

@export_group("World")
@export var ground_y: float = 820.0
@export var camera_anchor: float = 0.30
@export var camera_ground_fraction: float = 0.78
@export var player_height: float = 240.0
@export var player_start_x: float = 380.0
@export var starter_width: float = 1700.0
@export var platform_thickness: float = 58.0
@export var platform_min_width: float = 480.0
@export var platform_max_width: float = 940.0
@export var platform_y_min: float = 700.0
@export var platform_y_max: float = 880.0
@export var step_up_max: float = 140.0
@export var step_down_max: float = 180.0
## Gaps are a fraction of a full single-jump reach at the current speed.
@export var gap_reach_min: float = 0.28
@export var gap_reach_max: float = 0.56
@export var gap_reach_long: float = 0.80
@export var long_gap_chance: float = 0.16
@export var gap_absolute_min: float = 120.0
@export var gap_absolute_max: float = 680.0
@export var spawn_ahead: float = 2800.0
@export var despawn_behind: float = 1000.0

@export_group("Monsters")
@export var monster_chance_start: float = 0.36
@export var monster_chance_max: float = 0.70
@export var flyer_chance: float = 0.28
@export var flyer_height: float = 118.0
@export var telegraph_time: float = 0.50
@export var telegraph_extra_px: float = 240.0
@export var first_quiet_distance: float = 1600.0
@export var landing_pocket: float = 210.0
@export var min_monster_gap: float = 540.0

@export_group("Score")
@export var lives_per_run: int = 3
@export var points_per_pixel: float = 0.12
@export var kill_points: int = 100
