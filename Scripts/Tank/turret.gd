extends Node2D

@export var max_angular_speed: float = 3.0
@export var angular_accel: float = 5.0
@export var angular_decel: float = 24.0
@export var angle_tolerance: float = 0.01
@export var kp: float = 12.0
@export var kd: float = 2.0

@onready var crosshair: Node2D = get_tree().current_scene.get_node("Crosshair")

var _relative_speed: float = 0.0

func _physics_process(delta: float) -> void:
	if crosshair == null:
		return

	var target_global_angle: float = (crosshair.global_position - global_position).angle() + PI / 2

	var hull_angle: float = get_parent().global_rotation
	var target_relative_angle: float = wrapf(target_global_angle - hull_angle, -PI, PI)
	
	var angle_diff: float = wrapf(target_relative_angle - rotation, -PI, PI)

	var desired_speed: float = clamp(
		kp * angle_diff - kd * _relative_speed,
		-max_angular_speed,
		max_angular_speed
	)

	_relative_speed = move_toward(_relative_speed, desired_speed, angular_accel * delta)

	if abs(angle_diff) < angle_tolerance and abs(_relative_speed) < 0.02:
		_relative_speed = 0.0
		rotation = target_relative_angle
		return

	rotation += _relative_speed * delta
