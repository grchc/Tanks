extends CharacterBody2D

@export var track_max_speed_forward: float = 250.0
@export var track_max_speed_reverse: float = 100.0
@export var track_acceleration: float = 150.0
@export var braking_deceleration: float = 450.0

@export var track_distance: float = 60.0
@export var max_track_diff: float = 0.6
@export var pivot_turn_speed: float = 50.0

# Коэффициент трения о стену (0 = нет трения, 1 = полная остановка при боковом касании)
@export var wall_friction: float = 0.1

@onready var left_track: AnimatedSprite2D = $Tracks/LeftTrack
@onready var right_track: AnimatedSprite2D = $Tracks/RightTrack

var left_track_speed: float = 0.0
var right_track_speed: float = 0.0
var current_linear_speed: float = 0.0
var current_angular_speed: float = 0.0


func _physics_process(delta: float) -> void:
	_read_input()
	_handle_tracks(delta)
	_apply_tank_physics(delta)
	move_and_slide()
	_handle_wall_collision(delta)
	left_track.update(left_track_speed, current_angular_speed, delta)
	right_track.update(right_track_speed, current_angular_speed, delta)


func _read_input() -> Vector2:
	return Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_forward") - Input.get_action_strength("move_backward")
	)


func _handle_tracks(delta: float) -> void:
	var input := _read_input()
	var forward_input := input.y
	var turn_input := input.x

	var is_idle : bool = abs(forward_input) < 0.01 and abs(turn_input) < 0.01
	if is_idle:
		left_track_speed = move_toward(left_track_speed, 0.0, braking_deceleration * delta)
		right_track_speed = move_toward(right_track_speed, 0.0, braking_deceleration * delta)
		return
	var targets := _compute_target_speeds(forward_input, turn_input)
	left_track_speed = _approach_speed(left_track_speed, targets.left, delta)
	right_track_speed = _approach_speed(right_track_speed, targets.right, delta)


func _compute_target_speeds(forward_input: float, turn_input: float) -> Dictionary:
	var pivot_weight := smoothstep(0.0, 1.0, 1.0 - clamp(abs(forward_input), 0.0, 1.0))

	var turn_speed := turn_input * pivot_turn_speed
	var pivot_left := -turn_speed
	var pivot_right := turn_speed

	var base_speed := 0.0
	if forward_input > 0.0:
		base_speed = forward_input * track_max_speed_forward
	elif forward_input < 0.0:
		base_speed = forward_input * track_max_speed_reverse

	var turn_offset : float = turn_input * max_track_diff * abs(base_speed)
	var drive_left := base_speed - turn_offset
	var drive_right := base_speed + turn_offset

	var target_left : float = clamp(lerp(drive_left, pivot_left, pivot_weight), -track_max_speed_reverse, track_max_speed_forward)
	var target_right : float = clamp(lerp(drive_right, pivot_right, pivot_weight), -track_max_speed_reverse, track_max_speed_forward)

	return {"left": target_left, "right": target_right}


func _apply_tank_physics(delta: float) -> void:
	current_linear_speed = (left_track_speed + right_track_speed) * 0.5
	current_angular_speed = (right_track_speed - left_track_speed) / track_distance
	rotation = wrapf(rotation + current_angular_speed * delta, -PI, PI)
	velocity = Vector2.UP.rotated(rotation) * current_linear_speed


func _handle_wall_collision(_delta: float) -> void:
	if get_slide_collision_count() == 0:
		return

	# Собираем суммарную нормаль всех контактов
	var combined_normal := Vector2.ZERO
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		combined_normal += col.get_normal()

	if combined_normal.is_zero_approx():
		return

	combined_normal = combined_normal.normalized()
	var tank_forward := Vector2.UP.rotated(rotation)

	# Насколько танк движется «в» стену (отрицательное значение = едем в стену)
	var dot_into_wall := tank_forward.dot(-combined_normal)

	# Если танк не движется в стену — трение не применяем
	# (например, едем вдоль стены или отъезжаем от неё)
	if dot_into_wall <= 0.0:
		return

	# dot_into_wall ∈ (0, 1]:
	#   ~0  — движемся почти параллельно стене (скользим) — почти нет торможения
	#   ~1  — движемся перпендикулярно (прямо в лоб) — максимальное торможение
	var friction_strength := dot_into_wall * wall_friction

	# Проецируем скорость гусениц на направление «вдоль стены»
	# Компонента вдоль стены — единственная допустимая при упоре в неё
	var wall_tangent := Vector2(-combined_normal.y, combined_normal.x)
	var tank_right := Vector2.RIGHT.rotated(rotation)

	# Знаковая проекция правой оси танка на касательную стены
	# Нужна чтобы понять, насколько «вперёд» по гусенице соответствует движению вдоль стены
	var right_along_wall := tank_right.dot(wall_tangent)
	var forward_along_wall := tank_forward.dot(wall_tangent)

	# Скалярная скорость вдоль стены для каждой гусеницы
	# left track point = center - right*(track_distance/2)
	# right track point = center + right*(track_distance/2)
	# Но нам достаточно знать, какая доля скорости допустима
	var left_along  := left_track_speed * forward_along_wall
	var right_along := right_track_speed * forward_along_wall

	# Тормозим гусеницы пропорционально силе трения:
	# оставляем только допустимую (вдоль стены) часть, убираем forbidden часть
	# new_speed = current_speed * (1 - friction_strength) + allowed_component * friction_strength
	# Упрощённо: замедляем линейную скорость, сохраняя угловую (разворот вдоль стены не блокируем)
	var avg_speed := (left_track_speed + right_track_speed) * 0.5
	var diff_speed := (right_track_speed - left_track_speed) * 0.5  # half-difference для поворота

	# Тормозим только среднюю (линейную) часть, пропорционально углу удара
	var braked_avg := avg_speed * (1.0 - friction_strength)

	# Угловую часть (разворот) оставляем — танк может разворачиваться у стены
	left_track_speed  = braked_avg - diff_speed
	right_track_speed = braked_avg + diff_speed

	# Гарантируем, что velocity после корректировки не толкает в стену
	# CharacterBody2D уже обнулил компоненту velocity в нормаль через move_and_slide,
	# но пересчитываем на основе обновлённых скоростей гусениц
	current_linear_speed = (left_track_speed + right_track_speed) * 0.5
	velocity = Vector2.UP.rotated(rotation) * current_linear_speed


func _approach_speed(current: float, target: float, delta: float) -> float:
	var accel := braking_deceleration if (sign(current) != sign(target) and abs(current) > 0.01) else track_acceleration
	return move_toward(current, target, accel * delta)
