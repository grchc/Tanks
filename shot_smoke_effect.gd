extends Node2D

var initial_velocity: Vector2 = Vector2.ZERO

@export var damping: float = 0.92

@export var initial_alpha: float = 1

@export var final_alpha: float = 0.8

@export var fade_out: bool = true

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _velocity: Vector2 = Vector2.ZERO
var _duration: float = 0.0
var _elapsed: float = 0.0

func _ready() -> void:
	_velocity = initial_velocity

	var frames: SpriteFrames = sprite.sprite_frames
	var frame_count: int = frames.get_frame_count("smoke")
	var fps: float = frames.get_animation_speed("smoke")
	_duration = frame_count / fps

	modulate.a = initial_alpha
	sprite.play("smoke")

	get_tree().create_timer(_duration).timeout.connect(queue_free)

func _process(delta: float) -> void:
	_elapsed += delta

	position += _velocity * delta
	_velocity *= pow(damping, delta * 60.0)

	if fade_out and _duration > 0.0:
		var t: float = clamp(_elapsed / _duration, 0.0, 1.0)
		modulate.a = lerp(initial_alpha, final_alpha, t)
