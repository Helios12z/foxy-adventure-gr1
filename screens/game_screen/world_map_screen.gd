extends Control
class_name WorldMapScreen

## World map screen for stage selection

@onready var stages_control: Control = $StagesControl

@export_group("Debug")
## Force unlock stages up to this number (0 = Disabled)
## E.g., set to 2 -> Stage 1 & 2 marked completed, Stage 3 becomes Next Stage
@export var debug_completed_stages_count: int = 0

var loading_music_player: AudioStreamPlayer
const LOADING_MUSIC_PATH = "res://asset/sounds/Loading_music.mp3" 

func _ready() -> void:
	# RESET LOGIC: When entering World Map
	# 1. Clear boss defeated status
	GameManager.boss_defeated_by_stage.clear()
	
	# 2. Preserve latest checkpoint as "world_map_state" for next run
	if not GameManager.current_checkpoint_id.is_empty():
		var latest_data = GameManager.load_checkpoint(GameManager.current_checkpoint_id)
		if not latest_data.is_empty():
			# Store the complete latest checkpoint under a global key
			GameManager.checkpoint_data["world_map_state"] = latest_data
			print("Saved latest checkpoint to world_map_state: coins=", latest_data.get("inventory_data", {}).get("coins", 0))
	
	# 3. Delete level-specific checkpoint IDs (so they can be reactivated)
	# Keep only: completed_stages, collected_coins_by_stage, world_map_state, init
	var keys_to_remove = []
	for key in GameManager.checkpoint_data.keys():
		# Check if it's a checkpoint ID (contains "/root/" or starts with "Checkpoint")
		if (key.begins_with("/root/") or key.begins_with("Checkpoint")) and key != "world_map_state":
			keys_to_remove.append(key)
	
	for key in keys_to_remove:
		GameManager.checkpoint_data.erase(key)
		print("Removed checkpoint ID: ", key)
	
	# 4. Set current checkpoint to world_map_state
	GameManager.current_checkpoint_id = "world_map_state"
	GameManager.save_checkpoint_data()
	print("World Map: Reset complete. Current checkpoint: ", GameManager.current_checkpoint_id)

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
	
	# Play loading music in background
	_setup_loading_music()

func _input(event: InputEvent) -> void:
	# Cheat code: Unlock all maps (Press '7' or usage of 'unlock_all_map' action)
	if event.is_action_pressed("unlock_all_map"):
		_unlock_all_content_cheat()
		return

	# Fallback: Direct check for key '7' (Web compatibility)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_7 or event.keycode == KEY_7:
			_unlock_all_content_cheat()

func _unlock_all_content_cheat() -> void:
	print("CHEAT ACTIVATED: Unlocking all maps and checkpoints!")
	
	# 1. Unlock all stages (1 to 9)
	var all_stages = []
	for i in range(1, 10):
		all_stages.append(i)
	
	GameManager.checkpoint_data["completed_stages"] = all_stages
	print("Cheat: Set completed_stages to: ", all_stages)
	
	# 2. Save immediately so it persists in itch.io / web local storage
	GameManager.save_checkpoint_data()
	
	# 3. Refresh UI
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

func _setup_loading_music() -> void:
	loading_music_player = AudioStreamPlayer.new()
	add_child(loading_music_player)
	
	if ResourceLoader.exists(LOADING_MUSIC_PATH):
		var stream = load(LOADING_MUSIC_PATH)
		if stream:
			# Make it loop continuously
			if stream is AudioStreamMP3:
				stream.loop = true
			elif stream is AudioStreamOggVorbis:
				stream.loop = true
			
			loading_music_player.stream = stream
			loading_music_player.bus = "Music"
			loading_music_player.play()
			print("World Map: Loading music started")
	else:
		push_warning("Loading music file not found at: " + LOADING_MUSIC_PATH)

