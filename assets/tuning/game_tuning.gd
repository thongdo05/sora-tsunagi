class_name GameTuning
extends Resource

## Every gameplay number for this build lives here. The run starts in Moonheld.
## Edit game_tuning.tres and run again. Units are pixels and seconds.
## Full jump height is jump_velocity^2 / (2 * rise_gravity). A tap cuts that
## with jump_cut_scale. Falls use fall_gravity, so the arc is not a float.

@export_group("Run")
@export var run_speed_start: float = 460.0
## Speed at the end of pace_ramp_seconds. The climb between start and this is the felt ramp.
@export var run_speed_ramp_end: float = 900.0
@export var run_speed_max: float = 1120.0
## Pixels per second added after the ramp window, until run_speed_max.
@export var run_acceleration: float = 8.0
## How fast horizontal speed eases back to the run after a dash. Not a snap.
@export var dash_ease_out: float = 0.10

@export_group("Backdrop")
## Fraction of the run speed. Far is the moon and rift, mid is the ships, near is the water.
@export var bg_far_scroll: float = 0.05
@export var bg_mid_scroll: float = 0.12
@export var bg_near_scroll: float = 0.22
## Minimum width of one copy, in viewport widths. The loop is at least this wide.
@export var bg_far_span: float = 2.4
@export var bg_mid_span: float = 3.2
@export var bg_near_span: float = 5.5
## Screen-space drift of the cloud wisps, pixels per second. The moon plate itself stays on parallax.
@export var bg_cloud_drift: float = 14.0
@export var bg_sea_shimmer: float = 0.85
## Slow vertical breath of the far sky, in pixels.
@export var bg_sky_bob: float = 7.0

@export_group("Pace")
## Seconds from the start of a run until speed and monster density reach the ramp end.
@export var pace_ramp_seconds: float = 45.0
## 1 is a smoothstep across the window. Higher keeps the opening calmer, then climbs harder late.
@export var pace_curve: float = 1.0

@export_group("Jump")
@export var jump_velocity: float = -980.0
@export var double_jump_velocity: float = -760.0
## Gravity while rising and still holding jump.
@export var rise_gravity: float = 2400.0
## Gravity while falling. Higher than rise, so the drop has weight.
@export var fall_gravity: float = 5600.0
## Gravity while vertical speed is inside apex_speed. A short hang, not a float.
@export var apex_gravity: float = 1800.0
@export var apex_speed: float = 70.0
## On release while rising, upward speed is multiplied by this once.
@export var jump_cut_scale: float = 0.45
## Holding jump while falling multiplies fall gravity. 1 = no float.
@export var fall_hold_scale: float = 1.0
@export var max_fall_speed: float = 1450.0
@export var coyote_time: float = 0.10
@export var jump_buffer: float = 0.10
## Plant-and-drive before the feet leave the ground. About two or three frames.
@export var takeoff_time: float = 0.05

@export_group("Landing")
## Downward speed above this plays a parkour roll and sheds a little speed.
@export var hard_land_speed: float = 820.0
## Fraction of run speed removed on a hard landing. Eases back, never stops the run.
@export var hard_land_loss: float = 0.10
@export var hard_land_recover: float = 0.40
## How long the hard-landing roll plays. The four keys are blended across this.
@export var roll_time: float = 0.52

@export_group("Dash")
@export var dash_distance: float = 360.0
@export var dash_duration: float = 0.34
@export var dash_cooldown: float = 0.55
@export var dash_buffer: float = 0.12
## 0 keeps the dash flat: vertical speed is zeroed and gravity pauses.
@export var dash_gravity_scale: float = 0.0
@export var lip_hop_velocity: float = -380.0

@export_group("Feel")
## Hard freeze on a kill. 0 pauses the world for hit_stop_ms. Above 0 uses that time scale instead.
@export var hit_stop_ms: int = 80
@export var hit_stop_time_scale: float = 0.0
@export var shake_strength: float = 38.0
@export var shake_duration: float = 0.30
@export var hurt_invuln: float = 1.5
## Real seconds of the fall / shatter before the fighter is placed on a platform.
@export var respawn_delay: float = 0.72
## World speed during that beat. The clock is real time, so this cannot run forever.
@export var death_slowmo_scale: float = 0.30
@export var death_slowmo_seconds: float = 0.62
@export var death_flash: float = 0.78
## Game over ignores taps for this long, so the death press cannot start a new run.
@export var restart_lock_ms: int = 900
@export var kill_margin: float = 90.0

@export_group("HUD")
## Floor insets in viewport pixels. Desktop stays near these. A phone safe area can only grow them.
@export var hud_safe_min_left: float = 36.0
@export var hud_safe_min_top: float = 18.0
@export var hud_safe_min_right: float = 36.0
@export var hud_safe_min_bottom: float = 24.0
## Used when a phone browser reports no env(safe-area-inset-*). Both sides, because landscape flips the notch.
@export var hud_phone_notch: float = 128.0
@export var hud_phone_home: float = 52.0

@export_group("World")
@export var ground_y: float = 820.0
@export var camera_anchor: float = 0.30
@export var camera_ground_fraction: float = 0.78
## On-screen height of the rig. Smaller than the first prototype's static sprite.
@export var player_height: float = 200.0
@export var player_start_x: float = 380.0
@export var starter_width: float = 1700.0
@export var platform_thickness: float = 58.0
@export var platform_min_width: float = 480.0
@export var platform_max_width: float = 940.0
@export var platform_y_min: float = 700.0
@export var platform_y_max: float = 880.0
@export var step_up_max: float = 130.0
@export var step_down_max: float = 180.0
@export var gap_reach_min: float = 0.28
@export var gap_reach_max: float = 0.56
@export var gap_reach_long: float = 0.80
@export var long_gap_chance: float = 0.16
@export var gap_absolute_min: float = 110.0
@export var gap_absolute_max: float = 640.0
## After the opening platforms, this chance swaps in a buoy or a short dock.
@export var short_platform_chance: float = 0.30
@export var buoy_width: float = 210.0
@export var plank_width: float = 370.0
@export var spawn_ahead: float = 2800.0
@export var despawn_behind: float = 1000.0

@export_group("Monsters")
@export var monster_chance_start: float = 0.14
@export var monster_chance_max: float = 0.82
@export var flyer_chance: float = 0.28
@export var flyer_height: float = 118.0
@export var telegraph_time: float = 0.50
@export var telegraph_extra_px: float = 240.0
@export var first_quiet_distance: float = 1600.0
@export var landing_pocket: float = 210.0
@export var min_monster_gap_start: float = 1080.0
@export var min_monster_gap_end: float = 320.0
## Extra float on top of the wisp's baked 3 px bob.
@export var wisp_bob_px: float = 8.0
@export var wisp_bob_period: float = 1.2
## Faint ellipse under the dark hound. Wisps cast nothing.
@export var hound_shadow_alpha: float = 0.22
## Growl is louder than the punch files, so it sits under them.
@export var hound_growl_db: float = -10.0
## The presence loop is about -46 LUFS, so 0 dB stays a quiet bed.
@export var wisp_presence_db: float = 0.0
@export var enemy_shatter_seconds: float = 0.55
@export var enemy_spark_seconds: float = 0.08

@export_group("Score")
@export var lives_per_run: int = 3
@export var points_per_pixel: float = 0.12
@export var kill_points: int = 100

@export_group("Slivers")
## Slivers along one jump arc, not counting a risky extra or a dash pair.
@export var sliver_jump_count: int = 4
## Height of the jump arc above the deck chord, in pixels.
@export var sliver_peak: float = 170.0
## A higher sliver that asks for a double jump.
@export var sliver_risky_peak: float = 290.0
@export var sliver_risky_chance: float = 0.42
## Chance a wide gap also gets a flat dash-line pair.
@export var sliver_dash_chance: float = 0.28
@export var sliver_pickup: float = 56.0
## Seconds of quiet before a collect streak's pitch resets.
@export var sliver_streak_gap: float = 0.55
@export var sliver_bob: float = 7.0
## Pixels of track between shard clusters. Clusters are occasional, not a trail.
@export var shard_cluster_gap: float = 1500.0
@export var shard_cluster_min: int = 3
@export var shard_cluster_max: int = 6
## Even spacing of a straight row, and how far above the deck it sits.
@export var shard_row_gap: float = 76.0
@export var shard_row_lift: float = 96.0
## Consecutive shards to reach x2, x3, x4, and x5. x1 is the start. Cap is x5.
@export var streak_x2: int = 5
@export var streak_x3: int = 12
@export var streak_x4: int = 20
@export var streak_x5: int = 30
## Shards collected to fill the dash meter.
@export var dash_meter_shards: int = 15
@export var overdrive_speed: float = 1.8
@export var overdrive_duration: float = 2.0
## Second tap inside this window upgrades a dash that already started. It does not delay the first tap.
@export var overdrive_tap_window: float = 0.25
@export var overdrive_smash_reach: float = 150.0
## Overdrive punch score, and the multiplier a future Guardian should take. Monsters still break in one hit.
@export var overdrive_damage_mult: float = 2.0
## Fist lightning on the Overdrive sheet, grown around the bolt so it reads.
@export var overdrive_fx_scale: float = 1.4
## Sky behind the platforms. 0 is clear, 1 is a solid curtain.
@export var overdrive_sky_dark: float = 0.38
@export var overdrive_sky_bolts: int = 3
## How long one bolt shape holds before the next. Long enough that it does not flicker.
@export var overdrive_sky_hold: float = 0.14
## Red wash on punch cell 6 only. Not white.
@export var overdrive_strike_flash: float = 0.22


## 0 at the start of a run, 1 once pace_ramp_seconds has elapsed. Shared by speed and density.
func pace_amount(elapsed: float) -> float:
	var u := clampf(elapsed / maxf(pace_ramp_seconds, 0.1), 0.0, 1.0)
	var smooth := u * u * (3.0 - 2.0 * u)
	if pace_curve <= 1.001:
		return smooth
	return pow(smooth, pace_curve)


func speed_for_time(elapsed: float) -> float:
	var speed := lerpf(run_speed_start, run_speed_ramp_end, pace_amount(elapsed))
	if elapsed > pace_ramp_seconds:
		speed += run_acceleration * (elapsed - pace_ramp_seconds)
	return minf(speed, run_speed_max)


func density_for_time(elapsed: float) -> float:
	return pace_amount(elapsed)


## Air time of a fully held jump, used so gaps stay crossable.
func jump_air_time() -> float:
	var speed := absf(jump_velocity)
	var rise := speed / maxf(rise_gravity, 1.0)
	var height := speed * speed / (2.0 * maxf(rise_gravity, 1.0))
	var fall := sqrt(2.0 * height / maxf(fall_gravity, 1.0))
	var hang := (2.0 * apex_speed) / maxf(apex_gravity, 1.0)
	return rise + fall + hang
