extends CharacterBody2D

@export var speed: float = 800.0
@export var lifetime: float = 3.0

var _age: float = 0.0
var _initialized: bool = false

func _ready() -> void:
	# Disable collision with the parent tank for the first frame.
	# The proper long-term fix is collision layers/masks in the editor.
	pass

func init(muzzle_global_rotation: float) -> void:
	velocity = Vector2.UP.rotated(muzzle_global_rotation) * speed
	global_rotation = muzzle_global_rotation
	_initialized = true

func _physics_process(delta: float) -> void:
	if not _initialized:
		return

	_age += delta
	if _age >= lifetime:
		_destroy()
		return

	var collision := move_and_collide(velocity * delta)
	if collision:
		_destroy()

func _destroy() -> void:
	var trail := get_node_or_null("BulletTrail")
	if trail and trail.has_method("detach_and_fade"):
		trail.detach_and_fade()
	queue_free()
