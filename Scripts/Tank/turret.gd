extends Node2D

@export var max_angular_speed: float = 3.0
@export var angular_accel: float = 5.0
@export var angular_decel: float = 24.0
@export var angle_tolerance: float = 0.01
@export var kp: float = 12.0
@export var kd: float = 2.0

@export var muzzle_flash_scene: PackedScene

# Кулдаун между выстрелами (в секундах)
@export var shoot_cooldown: float = 1.5

@onready var crosshair: Node2D = get_tree().current_scene.get_node("Crosshair")
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var muzzle_point: Node2D = $MuzzlePoint

var _relative_speed: float = 0.0
var _can_shoot: bool = true

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

	# Анимируем башню
	sprite.play("shoot")

	# Спавним вспышку в мировом пространстве
	_spawn_muzzle_flash()

	# Кулдаун через таймер
	get_tree().create_timer(shoot_cooldown).timeout.connect(func(): _can_shoot = true)

func _spawn_muzzle_flash() -> void:
	if muzzle_flash_scene == null:
		push_warning("Turret: muzzle_flash_scene не назначен!")
		return

	var flash: Node2D = muzzle_flash_scene.instantiate()

	# Добавляем в корень сцены — вспышка НЕ будет двигаться вместе с танком
	get_tree().current_scene.add_child(flash)

	# Берём мировую позицию и поворот дула в момент выстрела
	flash.global_position = muzzle_point.global_position
	flash.global_rotation = muzzle_point.global_rotation

func _on_sprite_animation_finished() -> void:
	if sprite.animation == "shoot":
		sprite.play("idle")
