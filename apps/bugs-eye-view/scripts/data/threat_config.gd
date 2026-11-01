class_name ThreatConfig
extends Resource
## Senses, alert tuning, movement and attack values for one threat type.

@export_group("Senses")
@export var sight_range: float = 40.0
@export var sight_angle_deg: float = 100.0
## Inside this radius threats notice you regardless of facing (peripheral).
@export var near_sense_radius: float = 3.0
@export var eye_height: float = 3.0
## Downward tilt of the gaze (humans look at the floor ahead).
@export var gaze_pitch_deg: float = 0.0
@export var min_visibility: float = 0.08
@export var hearing_radius: float = 18.0
@export var hearing_gain: float = 0.6
@export var scent_tracking: bool = false
@export var scent_radius: float = 14.0
@export var sense_interval: float = 0.1

@export_group("Alert")
@export var suspicion_gain: float = 1.6
@export var suspicion_decay: float = 0.25
@export var suspicious_threshold: float = 0.3
@export var alert_threshold: float = 1.0
@export var lose_sight_time: float = 1.5
@export var search_duration: float = 8.0

@export_group("Movement")
@export var patrol_speed: float = 6.0
@export var search_speed: float = 9.0
@export var chase_speed: float = 14.0
@export var turn_speed: float = 4.0

@export_group("Attack")
@export var attack_range: float = 10.0
@export var attack_windup: float = 0.7
@export var attack_cooldown: float = 2.0
@export var attack_radius: float = 2.5
@export var stun_duration: float = 4.0
