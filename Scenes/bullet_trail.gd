## bullet_trail.gd
## Attach to a Node2D named "BulletTrail", child of the bullet scene root.

extends Node2D

@export var max_points: int = 18
@export var sample_distance: float = 4.0
@export var trail_width: float = 2.0
@export var color_tip: Color = Color(1.0, 0.95, 0.7, 1.0)
@export var color_tail: Color = Color(0.8, 0.5, 0.15, 0.0)
@export var fade_speed: float = 3.5

var _points: Array[Vector2] = []
var _fading: bool = false
var _fade_alpha: float = 1.0

func _physics_process(delta: float) -> void:
	if _fading:
		_fade_alpha -= fade_speed * delta
		if _fade_alpha <= 0.0:
			queue_free()
			return
		queue_redraw()
		return

	var snapped_pos := Vector2(roundi(global_position.x), roundi(global_position.y))

	if _points.is_empty() or snapped_pos.distance_to(_points[-1]) >= sample_distance:
		_points.append(snapped_pos)
		if _points.size() > max_points:
			_points.remove_at(0)
		queue_redraw()

func _draw() -> void:
	var n := _points.size()
	if n < 2:
		return

	var radius: float = trail_width * 0.5

	# Все сегменты с градиентом
	for i in range(n - 1):
		var t := (float(i) + 0.5) / float(n - 1)
		var c := color_tip.lerp(color_tail, 1.0 - t)
		c.a *= _fade_alpha
		draw_line(to_local(_points[i]), to_local(_points[i + 1]), c, trail_width, false)

	# Круг только на хвосте (points[0]) — скругляет тупой конец.
	# Рисуется только после отсоединения от пули, пока пуля жива —
	# хвост и так уходит в прозрачность через color_tail.
	if _fading:
		var tip_color := color_tip
		tip_color.a *= _fade_alpha
		draw_circle(to_local(_points[-1]), radius, tip_color)

func detach_and_fade() -> void:
	if _fading:
		return
	_fading = true

	var root := get_tree().current_scene
	var saved_global_pos := global_position
	var saved_global_rot := global_rotation

	reparent(root, true)

	global_position = saved_global_pos
	global_rotation = saved_global_rot
