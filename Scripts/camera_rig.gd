# CameraRig.gd
extends Node2D

@export var look_ahead := 0.7
@export var smooth := 6.0

@onready var tank: Node2D = get_parent().get_node("Tank")
@onready var crosshair := get_parent().get_node("Crosshair")

func _process(delta):
	var target := tank.global_position.lerp(
		crosshair.global_position,
		look_ahead
	)

	global_position = global_position.lerp(
		target,
		smooth * delta
	)
