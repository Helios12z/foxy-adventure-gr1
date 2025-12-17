extends Node
## Debug helper for World Map progression system

func _ready() -> void:
	print("=== World Map Debug Helper ===")
	print_current_progression()

func _input(event: InputEvent) -> void:
	# Press F1 to reset progression
	if event.is_action_pressed("ui_accept") and Input.is_key_pressed(KEY_F1):
		reset_progression()
	
	# Press F2 to unlock all stages (for testing)
	if event.is_action_pressed("ui_accept") and Input.is_key_pressed(KEY_F2):
		unlock_all_stages()
	
	# Press F3 to print current progression
	if event.is_action_pressed("ui_accept") and Input.is_key_pressed(KEY_F3):
		print_current_progression()
	
	# Press F4 to complete stage 1 (for testing)
	if event.is_action_pressed("ui_accept") and Input.is_key_pressed(KEY_F4):
		complete_stage(1)
	
	# Press F5 to complete stage 2
	if event.is_action_pressed("ui_accept") and Input.is_key_pressed(KEY_F5):
		complete_stage(2)

func reset_progression() -> void:
	GameManager.checkpoint_data["completed_stages"] = []
	GameManager.save_checkpoint_data()
	print("✅ Progression reset! All stages locked except Stage 1")
	print_current_progression()

func unlock_all_stages() -> void:
	GameManager.checkpoint_data["completed_stages"] = [1, 2, 3, 4, 5, 6, 7, 8, 9]
	GameManager.save_checkpoint_data()
	print("✅ All stages unlocked!")
	print_current_progression()

func complete_stage(stage_id: int) -> void:
	var completed_stages = GameManager.checkpoint_data.get("completed_stages", [])
	if not completed_stages.has(stage_id):
		completed_stages.append(stage_id)
		GameManager.checkpoint_data["completed_stages"] = completed_stages
		GameManager.save_checkpoint_data()
		print("✅ Stage ", stage_id, " completed!")
	else:
		print("⚠️ Stage ", stage_id, " was already completed")
	print_current_progression()

func print_current_progression() -> void:
	var completed_stages = GameManager.checkpoint_data.get("completed_stages", [])
	print("\n=== Current Progression ===")
	print("Completed stages: ", completed_stages)
	
	for i in range(1, 10):
		var status = ""
		if completed_stages.has(i):
			status = "✅ COMPLETED"
		elif i == 1:
			status = "🔓 UNLOCKED (Always available)"
		elif completed_stages.has(i - 1):
			status = "⭐ NEXT (Unlocked, pulsing glow)"
		else:
			status = "🔒 LOCKED"
		
		print("Stage ", i, ": ", status)
	
	print("\nDebug Commands:")
	print("  F1 + Enter: Reset progression")
	print("  F2 + Enter: Unlock all stages")
	print("  F3 + Enter: Print current progression")
	print("  F4 + Enter: Complete Stage 1")
	print("  F5 + Enter: Complete Stage 2")
	print("========================\n")
