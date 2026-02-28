# Crosshair.gd
extends Node2D

@export var max_distance: float = 600.0
@export var sensitivity:  float = 1.8

@onready var tank: Node2D = get_parent().get_node("Tank")

var offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	offset = Vector2.ZERO
	global_position = tank.global_position

func _process(_delta: float) -> void:
	global_position = tank.global_position + offset

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			return
		var d: Vector2 = event.relative * sensitivity
		offset += d
		var len := offset.length()
		if len > max_distance:
			offset = offset / len * max_distance
