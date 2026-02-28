extends Node2D

@export var fade_time := 0.5
@export var lifetime := 15.0

@onready var sprite := $Sprite2D

func _ready():
	# стартовая прозрачность = 1.0
	sprite.modulate.a = 1.0
	# таймаут - через lifetime начинаем фейд
	var t = Timer.new()
	t.one_shot = true
	t.wait_time = lifetime
	add_child(t)
	t.start()
	t.timeout.connect(_on_timeout)


func _on_timeout():
	var tw = create_tween()
	tw.tween_property(sprite, "modulate:a", 0.0, fade_time)
	tw.finished.connect(queue_free)
