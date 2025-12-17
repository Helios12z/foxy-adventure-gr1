extends Control
class_name WorldMapScreen

## World map screen for stage selection

@onready var stages_control: Control = $StagesControl

@export_group("Debug")
## Force unlock stages up to this number (0 = Disabled)
## E.g., set to 2 -> Stage 1 & 2 marked completed, Stage 3 becomes Next Stage
@export var debug_completed_stages_count: int = 0 

func _ready() -> void:
	# Clean up any leftover UI overlays (Victory/Defeat screens, etc.)
	cleanup_overlay_screens()
	
	# DEBUG: Forge checkpoint data
	if debug_completed_stages_count > 0:
		print("🐞 DEBUG MODE: Forcing completed stages up to count: ", debug_completed_stages_count)
		
		# CRITICAL FIX: Reset the array completely to ensure clean integer data
		# This prevents type mismatch (e.g. floats vs ints) or old data pollution
		var new_completed_list = []
		for i in range(1, debug_completed_stages_count + 1):
			new_completed_list.append(int(i)) # Force INT
			
		GameManager.checkpoint_data["completed_stages"] = new_completed_list
		print("🐞 Debug Data Set: ", GameManager.checkpoint_data["completed_stages"])
	
	# Update all stage buttons
	update_all_stages()

func cleanup_overlay_screens() -> void:
	# Remove any Victory/Defeat screens that might still be in the scene tree
	var root = get_tree().root
	var children_to_remove = []
	
	for child in root.get_children():
		# Check if it's a Victory or Defeat screen (or any CanvasLayer overlay)
		if child is VictoryScreen or child is DefeatScreen:
			children_to_remove.append(child)
			print("Cleaning up overlay screen: ", child.name)
		# Also check for any CanvasLayer with high layer number (overlays)
		elif child is CanvasLayer and child.layer >= 100:
			children_to_remove.append(child)
			print("Cleaning up high-layer CanvasLayer: ", child.name)
	
	# Remove them
	for child in children_to_remove:
		child.queue_free()
	
	print("Cleanup complete. Removed ", children_to_remove.size(), " overlay screens")

func update_all_stages() -> void:
	if not stages_control:
		return
	
	# Update each stage button
	for i in range(1, 10):  # Stages 1-9
		var stage_node = stages_control.get_node_or_null("Stage" + str(i))
		if stage_node and stage_node is StageButton:
			stage_node.update_stage_status()
