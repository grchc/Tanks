extends Node2D

func _ready():
	$AnimatedSprite2D.play("fire")
	$AnimatedSprite2D.animation_finished.connect(queue_free)
