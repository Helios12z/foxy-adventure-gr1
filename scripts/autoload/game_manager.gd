extends Node

#target portal name is the name of the portal to which the player will be teleported
var target_portal_name: String = ""
# Checkpoint system variables
var current_checkpoint_id: String = ""
var checkpoint_data: Dictionary = {}

var current_stage: Node = null
var player: Player = null

var inventory_system: InvetorySystem = null

func _ready() -> void:
	# Load checkpoint data when game starts
	load_checkpoint_data()
		# Init inventory system
	inventory_system = InvetorySystem.new()
	inventory_system.name = "InventorySystem" 
	add_child(inventory_system)
	pass

#change stage by path and target portal name
func change_stage(stage_path: String, _target_portal_name: String = "") -> void:
	target_portal_name = _target_portal_name
	#change scene to stage path
	get_tree().change_scene_to_file(stage_path)


#call from dialogic
func call_from_dialogic(msg:String = ""):
	#Dialogic.VAR["PlayerScore"] = 30
	print("Call from dialogic " + msg)


#respawn at portal or door
func respawn_at_portal() -> bool:
	if target_portal_name.is_empty():
		return false
	# Đảm bảo player hợp lệ sau khi đổi scene
	if not is_instance_valid(player):
		var p := get_tree().current_scene.find_child("Player", true, false)
		if p is Player:
			player = p as Player
		else:
			return false
	# Xác định node portal/door theo tên hoặc đường dẫn
	var portal: Node = null
	if target_portal_name.find("/") != -1:
		portal = current_stage.get_node_or_null(NodePath(target_portal_name))
	else:
		portal = current_stage.find_child(target_portal_name, true, false)
	if portal is Node2D and is_instance_valid(player):
		player.global_position = (portal as Node2D).global_position
		target_portal_name = ""
		_apply_checkpoint_inventory_only()
		# Đồng bộ stage_path của checkpoint sang stage hiện tại để respawn sau chết không bị bỏ qua
		update_current_checkpoint_player_state({}, true)
		return true
	return false

func _apply_checkpoint_inventory_only() -> void:
	if player == null:
		return
	if current_checkpoint_id.is_empty():
		return
	var checkpoint_info: Dictionary = checkpoint_data.get(current_checkpoint_id, {})
	var data: Dictionary = checkpoint_info.get("player_state", {})
	if data.is_empty():
		return
	# Chỉ áp dụng các trạng thái, không thay đổi vị trí
	if data.has("has_blade"):
		player.has_blade = data["has_blade"]
		Dialogic.VAR.set("HasBlade", player.has_blade)
		if player.has_blade:
			player.collected_blade()
	if data.has("has_fire_gem") and bool(data["has_fire_gem"]):
		player.collected_fire_gem()
	if data.has("has_water_paw_gem") and bool(data["has_water_paw_gem"]):
		player.collected_water_paw_gem()
	if data.has("has_water_room_gem") and bool(data["has_water_room_gem"]):
		player.collected_water_room_gem()


# Checkpoint system functions
func save_checkpoint(checkpoint_id: String) -> void:
	current_checkpoint_id = checkpoint_id
	var player_state_dict: Dictionary = player.save_state()
	var inventory_data: Dictionary = inventory_system.save_data()
	checkpoint_data[checkpoint_id] = {
		"player_state":player_state_dict,
		"stage_path": current_stage.scene_file_path,
		"inventory_data": inventory_data
	}
	print("Checkpoint saved: ", checkpoint_id)


func load_checkpoint(checkpoint_id: String) -> Dictionary:
	if checkpoint_id in checkpoint_data:
		return checkpoint_data[checkpoint_id]
	return {}

#respawn at checkpoint
func respawn_at_checkpoint() -> void:
	if current_checkpoint_id.is_empty():
		print("No checkpoint available")
		return
	
	var checkpoint_info = checkpoint_data.get(current_checkpoint_id, {})
	if checkpoint_info.is_empty():
		print("Checkpoint data not found")
		return
	
	# Load the stage if different
	var checkpoint_stage = checkpoint_info.get("stage_path", "")
	
	if current_stage.scene_file_path != checkpoint_stage and not checkpoint_stage.is_empty():
		return
		
	# Can change stage if different but not implemented yet to test
	#	change_stage(checkpoint_stage, "")
	#	# Wait for scene to load
	#	await get_tree().process_frame

	if player != null:
		var player_state: Dictionary = checkpoint_info.get("player_state")
		if player_state == null:
			return
		player.load_state(player_state)
		print("Player respawned at checkpoint: ", current_checkpoint_id)
	else:
		print("Player not found for respawn")
	
	if inventory_system != null:
		var inventory_data = checkpoint_info.get("inventory_data")
		if inventory_data != null:
			inventory_system.coins = inventory_data["coins"]
			inventory_system.keys = inventory_data["keys"]

#check if there is a checkpoint
func has_checkpoint() -> bool:
	return not current_checkpoint_id.is_empty()

# Save checkpoint data to persistent storage
func save_checkpoint_data() -> void:
	var save_data = {
		"current_checkpoint_id": current_checkpoint_id,
		"checkpoint_data": checkpoint_data
	}
	SaveSystem.save_checkpoint_data(save_data)

# Load checkpoint data from persistent storage
func load_checkpoint_data() -> void:
	var save_data = SaveSystem.load_checkpoint_data()
	if not save_data.is_empty():
		current_checkpoint_id = save_data.get("current_checkpoint_id", "")
		checkpoint_data = save_data.get("checkpoint_data", {})
		print("Checkpoint data loaded from save file")

# Clear all checkpoint data
func clear_checkpoint_data() -> void:
	current_checkpoint_id = ""
	checkpoint_data.clear()
	SaveSystem.delete_save_file()
	print("All checkpoint data cleared")
	
func collect_blade() -> void:
	if player:
		player.collected_blade()
		Dialogic.VAR.set("HasBlade", true)
		update_current_checkpoint_player_state({"has_blade": true}, true)

func collect_fire_gem() -> void:
	if player:
		player.collected_fire_gem()
		update_current_checkpoint_player_state({"has_fire_gem": true}, true)

func collect_water_paw_gem() -> void:
	if player:
		player.collected_water_paw_gem()
		update_current_checkpoint_player_state({"has_water_paw_gem": true}, true)

func collect_water_room_gem() -> void:
	if player:
		player.collected_water_room_gem()
		update_current_checkpoint_player_state({"has_water_room_gem": true}, true)

func ensure_initial_checkpoint() -> void:
	# Create or adopt an initial checkpoint with starting position
	if player == null or current_stage == null:
		return
	if current_checkpoint_id.is_empty():
		if checkpoint_data.has("init"):
			current_checkpoint_id = "init"
			return
		var init_state: Dictionary = player.save_state()
		checkpoint_data["init"] = {
			"player_state": init_state,
			"stage_path": current_stage.scene_file_path
		}
		current_checkpoint_id = "init"
		save_checkpoint_data()

func update_current_checkpoint_player_state(updates: Dictionary, create_if_missing: bool = true) -> void:
	# Merge selective player state fields into the current checkpoint.
	# Does not alter the saved position unless provided in updates.
	if player == null or current_stage == null:
		return
	if current_checkpoint_id.is_empty():
		if create_if_missing:
			ensure_initial_checkpoint()
		else:
			return
	var chk_id: String = current_checkpoint_id
	var checkpoint_info: Dictionary = checkpoint_data.get(chk_id, {})
	var player_state: Dictionary = checkpoint_info.get("player_state", {})
	for key in updates.keys():
		player_state[key] = updates[key]
	checkpoint_info["player_state"] = player_state
	checkpoint_info["stage_path"] = current_stage.scene_file_path
	checkpoint_data[chk_id] = checkpoint_info
	save_checkpoint_data()
