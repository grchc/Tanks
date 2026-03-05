## turret_aim_ui.gd
## Attach this script to a Node2D child of the Turret node.
## Draws a pixel-art dashed line along the CURRENT barrel direction.
## Line length equals the distance from turret center to crosshair.
## An arrowhead chevron is drawn at the end of the line.
## Changes color when the barrel is aimed at the crosshair.

extends Node2D

@export_group("Colors")
@export var color_aiming: Color = Color(0.0, 0.718, 0.937, 1.0)
@export var color_locked: Color = Color(1.0, 1.0, 1.0, 1.0)

@export_group("Line style")
@export var dash_length: int = 6
@export var gap_length: int = 4
@export var line_width: float = 1.0

@export_group("Arrowhead")
## Half-width of the chevron in pixels
@export var arrow_half_width: float = 6.0
## Depth (length) of the chevron in pixels
@export var arrow_depth: float = 6.0

@export_group("Alignment")
@export var locked_tolerance: float = 0.08

@onready var _crosshair: Node2D = get_tree().current_scene.get_node("Crosshair")

var _is_locked: bool = false

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if _crosshair == null:
		return

	var to_crosshair_world: Vector2 = _crosshair.global_position - global_position
	var dist: float = to_crosshair_world.length()
	if dist < 1.0:
		return

	# Check alignment
	var barrel_dir_world: Vector2 = Vector2.UP.rotated(global_rotation)
	var to_crosshair_dir: Vector2 = to_crosshair_world / dist
	var angle_diff: float = abs(wrapf(barrel_dir_world.angle_to(to_crosshair_dir), -PI, PI))
	_is_locked = angle_diff < locked_tolerance

	var color: Color = color_locked if _is_locked else color_aiming

	# Barrel direction in local space; length = distance to crosshair
	var barrel_dir_local: Vector2 = Vector2.UP.rotated(rotation)
	var tip: Vector2 = barrel_dir_local * dist

	# Leave a small gap before the arrowhead so the dash doesn't overlap it
	var line_end: Vector2 = barrel_dir_local * (dist - arrow_depth)
	_draw_pixel_dashed_line(Vector2.ZERO, line_end, color)

	# Draw chevron arrowhead at the tip
	_draw_chevron(tip, barrel_dir_local, color)


## Draws a V-shaped chevron pointing in `dir` with its tip at `tip`.
func _draw_chevron(tip: Vector2, dir: Vector2, color: Color) -> void:
	# Perpendicular axis
	var perp: Vector2 = Vector2(-dir.y, dir.x)
	# Base of the chevron sits `arrow_depth` behind the tip
	var base_center: Vector2 = tip - dir * arrow_depth
	var left:  Vector2 = (base_center - perp * arrow_half_width).round()
	var right: Vector2 = (base_center + perp * arrow_half_width).round()
	tip = tip.round()
	draw_line(left,  tip,   color, line_width, false)
	draw_line(right, tip,   color, line_width, false)


func _draw_pixel_dashed_line(from: Vector2, to: Vector2, color: Color) -> void:
	var total_length: float = from.distance_to(to)
	if total_length < 1.0:
		return

	var direction: Vector2 = (to - from).normalized()
	var step: int = dash_length + gap_length
	var pos: float = 0.0

	while pos < total_length:
		var dash_start: Vector2 = (from + direction * pos).round()
		var dash_end: Vector2 = (from + direction * min(pos + dash_length, total_length)).round()
		draw_line(dash_start, dash_end, color, line_width, false)
		pos += step


func is_locked() -> bool:
	return _is_locked
