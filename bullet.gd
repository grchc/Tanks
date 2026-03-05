## bullet.gd
## Attach to an Area2D node (the bullet scene root).
## Scene structure:
##   Area2D        <-- this script
##     Sprite2D
##     CollisionShape2D
##     Node2D "Trail"  <-- bullet_trail.gd

extends Area2D

@export var speed: float = 800.0
@export var lifetime: float = 3.0

var _velocity: Vector2 = Vector2.ZERO
var _age: float = 0.0
var _initialized: bool = false

func _ready() -> void:
	body_entered.connect(_on_hit)
	area_entered.connect(_on_area_hit)

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

func _on_hit(_body: Node) -> void:
	_destroy()

func _on_area_hit(_area: Area2D) -> void:
	_destroy()

func _destroy() -> void:
	var trail = get_node_or_null("Trail")
	if trail and trail.has_method("detach_and_fade"):
		trail.detach_and_fade()
	queue_free()
