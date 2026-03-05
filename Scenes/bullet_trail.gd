## bullet_trail.gd
## Attach to the Bullet (Area2D) directly — no child node needed.
## Creates a Line2D at scene root that follows the bullet in world space.

extends Area2D

# ── re-export bullet params (keep in one script) ─────────────────────────────
@export var speed: float = 800.0
@export var lifetime: float = 3.0

@export_group("Trail")
@export var max_points: int = 24
@export var width_head: float = 2.0
@export var width_tail: float = 1.0
@export var trail_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var fade_out_duration: float = 0.18

# ── internal ──────────────────────────────────────────────────────────────────
var _velocity: Vector2 = Vector2.ZERO
var _age: float = 0.0
var _initialized: bool = false

var _line: Line2D = null

func _ready() -> void:
	body_entered.connect(_on_hit)
	area_entered.connect(_on_area_hit)
	_create_line()

func init(muzzle_global_rotation: float) -> void:
	_velocity = Vector2.UP.rotated(muzzle_global_rotation) * speed
	_initialized = true

func _physics_process(delta: float) -> void:
	if not _initialized:
		return
	position += _velocity * delta
	_age += delta
	if _age >= lifetime:
		_destroy()
		return
	_update_line()

func _create_line() -> void:
	_line = Line2D.new()
	_line.width = width_head
	_line.default_color = trail_color
	_line.joint_mode = Line2D.LINE_JOINT_SHARP
	_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_line.end_cap_mode = Line2D.LINE_CAP_ROUND

	# Width gradient: thick at head (newest = last point), thin at tail
	var grad := Gradient.new()
	grad.set_color(0, Color(trail_color.r, trail_color.g, trail_color.b, 0.0))
	grad.set_color(1, trail_color)
	_line.width_curve = _make_width_curve()
	_line.gradient = grad

	# Add directly to scene root so it lives in world space
	get_tree().current_scene.add_child(_line)

func _make_width_curve() -> Curve:
	var c := Curve.new()
	c.add_point(Vector2(0.0, width_tail / width_head))
	c.add_point(Vector2(1.0, 1.0))
	return c

func _update_line() -> void:
	if _line == null:
		return
	# Add current world position snapped to pixel grid
	_line.add_point(global_position.round())
	# Trim oldest points
	while _line.get_point_count() > max_points:
		_line.remove_point(0)

func _on_hit(_body: Node) -> void:
	_destroy()

func _on_area_hit(_area: Area2D) -> void:
	_destroy()

func _destroy() -> void:
	if _line != null:
		_fade_and_free_line()
	queue_free()

func _fade_and_free_line() -> void:
	var line := _line
	_line = null
	var tween := get_tree().create_tween()
	tween.tween_method(
		func(a: float) -> void:
			if is_instance_valid(line):
				line.modulate.a = a,
		1.0, 0.0, fade_out_duration
	)
	tween.tween_callback(func() -> void:
		if is_instance_valid(line):
			line.queue_free()
	)
