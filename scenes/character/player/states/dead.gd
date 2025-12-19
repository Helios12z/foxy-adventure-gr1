extends PlayerState

var defeat_screen_shown: bool = false
var defeat_timer: Timer = null

func _enter():
	print("=== PLAYER ENTERED DEAD STATE ===")
	print("Health: ", obj.health, " / ", obj.max_health)
	
	#change animation to dead
	obj.change_animation("dead")
	obj.velocity.x = 0
	defeat_screen_shown = false
	
	# Create timer to show defeat screen after death animation
	defeat_timer = Timer.new()
	defeat_timer.wait_time = 1.0
	defeat_timer.one_shot = true
	defeat_timer.process_mode = Node.PROCESS_MODE_ALWAYS  # Work even when paused!
	defeat_timer.timeout.connect(_on_defeat_timer_timeout)
	add_child(defeat_timer)
	defeat_timer.start()
	
	print("Defeat timer started, will show screen in 1 second...")

func _on_defeat_timer_timeout():
	print("⏰ Defeat timer timeout!")
	if not defeat_screen_shown:
		defeat_screen_shown = true
		show_defeat_screen()
	
	if defeat_timer:
		defeat_timer.queue_free()
		defeat_timer = null

func _exit():
	if defeat_timer:
		defeat_timer.queue_free()
		defeat_timer = null

func _update(_delta: float):
	# Death state doesn't need to do anything in update
	pass

func show_defeat_screen() -> void:
	print("=== SHOWING DEFEAT SCREEN ===")
	print("Scene tree: ", get_tree())
	print("Root: ", get_tree().root)
	
	# Load and show defeat screen
	var defeat_screen_scene = load("res://screens/game_screen/defeat_screen.tscn")
	if defeat_screen_scene:
		print("✅ Defeat screen scene loaded successfully")
		var defeat_screen = defeat_screen_scene.instantiate()
		if defeat_screen:
			print("✅ Defeat screen instantiated successfully")
			# Add to root directly
			get_tree().root.add_child(defeat_screen)
			print("✅ Defeat screen added to root! Total children: ", get_tree().root.get_child_count())
			
			# List all children in root for debugging
			print("--- Root children: ---")
			for i in get_tree().root.get_child_count():
				var child = get_tree().root.get_child(i)
				print("  [", i, "] ", child.name, " (", child.get_class(), ")")
		else:
			push_error("❌ Failed to instantiate defeat_screen!")
	else:
		push_error("❌ Failed to load defeat_screen.tscn!")

# Ignore take damage
func take_damage(_damage: int = 1) -> void:
	pass
