class_name Tuning
extends Resource
## Driving-model and race tuning. Edit resources/tuning.tres in the editor
## to retune without touching code.

@export_group("Hover")
@export var hover_height := 0.9
@export var snap_range := 1.3
@export var gravity := 28.0
@export var air_steer := 0.35
# Glide (energy wings while airborne): sink rate, steering multiplier on
# top of air_steer, thruster share of ground acceleration, air time before
# the wings may unfold.
@export var glide_sink := 5.5
@export var glide_steer := 3.2
@export var glide_thrust := 0.8
@export var glide_min_air := 0.3
@export var glide_ratio := 7.0   # metres forward per metre down (a fast glider sinks faster, so landings don't depend on speed)

@export_group("Speed (from stats 1-10)")
@export var top_speed_base := 40.0
@export var top_speed_per_stat := 1.6
@export var accel_base := 13.0
@export var accel_per_stat := 1.8
@export var brake_decel := 38.0
@export var coast_decel := 7.0
@export var reverse_speed := 12.0

@export_group("Steering")
@export var steer_rate_base := 1.55
@export var steer_rate_per_stat := 0.09
@export var grip_base := 6.5
@export var grip_per_stat := 0.45
@export var high_speed_steer_loss := 0.38

@export_group("Drift & boost")
@export var drift_min_speed := 17.0
@export var drift_grip := 0.22
@export var drift_charge_rate := 46.0
@export var drift_tiers := PackedFloat32Array([34.0, 67.0, 100.0])
@export var drift_boost_time := PackedFloat32Array([0.55, 0.95, 1.5])
@export var boost_speed_mult := 1.32
@export var boost_accel := 55.0
@export var pad_boost_time := 0.9

@export_group("Energy")
@export var energy_max := 100.0
@export var energy_drain := 1.45
@export var energy_idle_share := 0.35
@export var pod_energy := 14.0
@export var trick_energy := 8.0
@export var near_miss_energy := 4.0
@export var slip_energy := 4.0
@export var emergency_speed := 0.55
@export var emergency_accel := 0.45

@export_group("Hits")
@export var spin_time := 1.1
@export var spin_speed_keep := 0.3
@export var invuln_after_hit := 1.2
@export var shield_time := 6.0

@export_group("Pro moves")
@export var start_boost_window := 0.45
@export var start_boost_time := 1.2
@export var stall_time := 0.7
@export var slip_range := 16.0
@export var slip_width := 3.2
@export var slip_charge_time := 1.1
@export var slip_boost_time := 0.8
@export var trick_min_air := 0.22
@export var trick_time := 0.55
@export var trick_boost_time := 0.9
