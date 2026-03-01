# CameraRig.gd
extends Node2D

@export var look_ahead := 0.7
@export var smooth := 6.0

@onready var tank: Node2D = get_parent().get_node("Tank")
@onready var crosshair := get_parent().get_node("Crosshair")

# Текущее смещение шейка
var _shake_offset: Vector2 = Vector2.ZERO
# Скорость затухания шейка (множитель в секунду)
var _shake_velocity: Vector2 = Vector2.ZERO

# Жёсткость пружины — как быстро шейк возвращается к нулю
const SHAKE_SPRING: float = 180.0
# Демпфирование — предотвращает бесконечные колебания
const SHAKE_DAMPING: float = 14.0

func _process(delta: float) -> void:
	# Обычное слежение
	var target := tank.global_position.lerp(
		crosshair.global_position,
		look_ahead
	)
	var base_pos: Vector2 = global_position.lerp(target, smooth * delta)

	# Физика пружины для шейка
	var spring_force: Vector2 = -SHAKE_SPRING * _shake_offset
	var damping_force: Vector2 = -SHAKE_DAMPING * _shake_velocity
	_shake_velocity += (spring_force + damping_force) * delta
	_shake_offset += _shake_velocity * delta

	global_position = base_pos + _shake_offset

# Вызывается снаружи при выстреле.
# direction — нормализованный вектор направления отдачи (обычно противоположный стволу)
# strength — сила импульса в пикселях
func apply_shake(direction: Vector2, strength: float) -> void:
	_shake_velocity += direction * strength
