extends Node2D

@export_file("*.tscn") var target_stage = ""
@export var target_door = "Door"
@export var is_cross_scene: bool = false

func load_next_stage():
	var current_scene = get_tree().current_scene
	if is_cross_scene:
		if target_stage != "":
			GameManager.change_stage(target_stage, target_door)
		return
	var door: Node = null
	if target_door.find("/") != -1:
		door = current_scene.get_node_or_null(NodePath(target_door))
	else:
		door = current_scene.find_child(target_door, true, false)
	if door is Node2D and GameManager.player != null:
		GameManager.player.global_position = (door as Node2D).global_position

func _on_interactive_area_2d_interacted() -> void:
	print("interacted")
	load_next_stage()
