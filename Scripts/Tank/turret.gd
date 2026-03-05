extends Node2D

@export var max_angular_speed: float = 3.0
@export var angular_accel: float = 5.0
@export var angular_decel: float = 24.0
@export var angle_tolerance: float = 0.01
@export var kp: float = 12.0
@export var kd: float = 2.0

@export var muzzle_flash_scene: PackedScene
@export var smoke_effect_scene: PackedScene
## Сцена снаряда — назначь в инспекторе
@export var bullet_scene: PackedScene

@export var smoke_initial_speed: float = 80.0
@export var shoot_cooldown: float = 0.5

@export_group("Camera Shake")
@export var shake_strength: float = 120.0
@export var shake_directional_weight: float = 0.8

@export_group("Recoil")
@export var recoil_impulse: float = 60.0

@onready var crosshair: Node2D = get_tree().current_scene.get_node("Crosshair")
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var muzzle_point: Node2D = $MuzzlePoint

var _relative_speed: float = 0.0
var _can_shoot: bool = true

## Таймер-нода для cooldown — безопаснее, чем create_timer(),
## т.к. не вызовется после удаления башни.
@onready var _cooldown_timer: Timer = _make_cooldown_timer()

func _make_cooldown_timer() -> Timer:
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = shoot_cooldown
	t.timeout.connect(func(): _can_shoot = true)
	add_child(t)
	return t

func _ready() -> void:
	sprite.animation_finished.connect(_on_sprite_animation_finished)

func _physics_process(delta: float) -> void:
	_rotate_toward_crosshair(delta)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_shoot()

# ---------------------------------------------------------------------------

func _rotate_toward_crosshair(delta: float) -> void:
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

func _shoot() -> void:
	if not _can_shoot:
		return

	_can_shoot = false
	sprite.play("shoot")
	_spawn_muzzle_flash()
	_spawn_smoke()
	_spawn_bullet()
	_apply_camera_shake()
	_apply_recoil()

	_cooldown_timer.wait_time = shoot_cooldown
	_cooldown_timer.start()

func _spawn_bullet() -> void:
	if bullet_scene == null:
		push_warning("Turret: bullet_scene не назначен!")
		return

	var bullet := bullet_scene.instantiate()

	# Устанавливаем позицию и направление ДО добавления в дерево,
	# чтобы _ready() пули видел корректные данные.
	# global_position работает только после add_child, поэтому:
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = muzzle_point.global_position
	bullet.init(muzzle_point.global_rotation)

func _spawn_muzzle_flash() -> void:
	if muzzle_flash_scene == null:
		push_warning("Turret: muzzle_flash_scene не назначен!")
		return

	var flash: Node2D = muzzle_flash_scene.instantiate()
	get_tree().current_scene.add_child(flash)
	flash.global_position = muzzle_point.global_position
	flash.global_rotation = muzzle_point.global_rotation

func _spawn_smoke() -> void:
	if smoke_effect_scene == null:
		push_warning("Turret: smoke_effect_scene не назначен!")
		return

	var smoke: Node2D = smoke_effect_scene.instantiate()
	get_tree().current_scene.add_child(smoke)
	smoke.global_position = muzzle_point.global_position
	smoke.global_rotation = muzzle_point.global_rotation

	var muzzle_dir: Vector2 = Vector2.UP.rotated(muzzle_point.global_rotation)
	smoke.initial_velocity = muzzle_dir * smoke_initial_speed

func _apply_camera_shake() -> void:
	var camera_rig = get_tree().current_scene.get_node_or_null("CameraRig")
	if camera_rig == null:
		push_warning("Turret: CameraRig не найден!")
		return

	var muzzle_dir: Vector2 = Vector2.UP.rotated(muzzle_point.global_rotation)
	var recoil_dir: Vector2 = -muzzle_dir
	var random_dir: Vector2 = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	var shake_dir: Vector2 = recoil_dir.lerp(random_dir, 1.0 - shake_directional_weight).normalized()

	camera_rig.apply_shake(shake_dir, shake_strength)

func _apply_recoil() -> void:
	if recoil_impulse <= 0.0:
		return

	var body := get_parent()
	if not body.has_method("apply_recoil"):
		push_warning("Turret: тело танка не имеет метода apply_recoil!")
		return

	var shot_dir: Vector2 = Vector2.UP.rotated(muzzle_point.global_rotation)
	body.apply_recoil(shot_dir, recoil_impulse)

func _on_sprite_animation_finished() -> void:
	if sprite.animation == "shoot":
		sprite.play("idle")
