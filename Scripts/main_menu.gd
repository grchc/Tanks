extends Control

const WORLD_SCENE = "res://Scenes/World.tscn"

@onready var deploy_button: Button = $CenterContainer/OuterPanel/PanelBody/DeployButton

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	deploy_button.pressed.connect(_on_deploy_pressed)

func _on_deploy_pressed() -> void:
	get_tree().change_scene_to_file(WORLD_SCENE)
