extends AnimatedSprite2D

@export var anim_speed_factor: float = 0.02
@export var anim_min_speed: float = 0.05

@export var track_mark_scene: PackedScene
@export var mark_spacing: float = 8.0
@export var mark_min_speed: float = 5.0

@onready var track_point: Node2D = $TrackPoint
@onready var track_marks_root: Node2D = get_tree().current_scene.get_node("TrackMarks")

var _dist_accum: float = 0.0

func update(track_speed: float, angular_speed: float, delta: float) -> void:
	_update_animation(track_speed)
	_process_track_marks(track_speed, angular_speed, delta)

func _update_animation(track_speed: float) -> void:
	if abs(track_speed) < anim_min_speed:
		stop()
		return
	if not is_playing():
		play("move")
	speed_scale = -track_speed * anim_speed_factor

func _process_track_marks(track_speed: float, angular_speed: float, delta: float) -> void:
	var tank: Node2D = get_parent().get_parent() # Tracks -> Tank
	
	var r: Vector2 = track_point.global_position - tank.global_position
	var forward_vec = Vector2.UP.rotated(tank.rotation)
	var linear_part = forward_vec * track_speed
	var angular_part = Vector2(-angular_speed * r.y, angular_speed * r.x)
	
	var point_velocity = linear_part + angular_part
	var speed = point_velocity.length()

	if speed < mark_min_speed:
		return

	_dist_accum += speed * delta
	if _dist_accum >= mark_spacing:
		_dist_accum -= mark_spacing
		_spawn_mark(point_velocity)

func _spawn_mark(velocity_vec: Vector2) -> void:
	var mark = track_mark_scene.instantiate()
	track_marks_root.add_child(mark)
	mark.global_position = track_point.global_position
	mark.rotation = velocity_vec.angle()
	mark.z_index = -1
