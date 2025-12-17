extends Node2D

@export_file("*.tscn") var target_stage = ""
@export var target_door = "Door"
@export var is_cross_scene: bool = false
@export_range(0, 9) var completes_stage_id: int = 0  # 0 = doesn't complete any stage, 1-9 = completes that stage
@export var triggers_victory_screen: bool = false  # If true, shows victory screen instead of loading next stage

func load_next_stage():
	# Mark stage as completed if applicable
	if completes_stage_id > 0:
		mark_stage_completed(completes_stage_id)
	
	# Show victory screen if this door triggers it
	if triggers_victory_screen:
		show_victory_screen()
		return
	
	var current_scene = get_tree().current_scene
	if is_cross_scene:
		if target_stage != "":
			GameManager.target_portal_name = target_door
			GameManager.change_stage_with_loading(target_stage)
		return
	var door: Node = null
	if target_door.find("/") != -1:
		door = current_scene.get_node_or_null(NodePath(target_door))
	else:
		door = current_scene.find_child(target_door, true, false)
	if door is Node2D and GameManager.player != null:
		GameManager.player.global_position = (door as Node2D).global_position
		# Save checkpoint at this door position
		save_checkpoint_at_door(door)

func mark_stage_completed(stage_id: int) -> void:
	var completed_stages = GameManager.checkpoint_data.get("completed_stages", [])
	if not completed_stages.has(stage_id):
		completed_stages.append(stage_id)
		GameManager.checkpoint_data["completed_stages"] = completed_stages
		GameManager.save_checkpoint_data()
		print("Stage ", stage_id, " marked as completed")

func save_checkpoint_at_door(door: Node2D) -> void:
	# Create a checkpoint ID based on the door
	var checkpoint_id = "door_" + door.name + "_" + str(door.get_path())
	
	# Save checkpoint with current player state at door position
	if GameManager.player:
		GameManager.save_checkpoint(checkpoint_id)
		print("Checkpoint saved at door: ", checkpoint_id)

func show_victory_screen() -> void:
	print("=== SHOWING VICTORY SCREEN ===")
	# Load and show victory screen
	var victory_screen_scene = load("res://screens/game_screen/victory_screen.tscn")
	if victory_screen_scene:
		var victory_screen = victory_screen_scene.instantiate()
		# Add to root, NOT to current_scene, to ensure it displays on top
		get_tree().root.add_child(victory_screen)
		print("Victory screen added to root successfully!")
	else:
		push_error("Failed to load victory_screen.tscn!")


func _on_interactive_area_2d_interacted() -> void:
	print("interacted")
	if GameManager.player and GameManager.player.is_giant_mode:
		GameManager.player.inactive_giant_form()
	load_next_stage()
