extends PlayerState

var defeat_screen_shown: bool = false
var defeat_timer: Timer = null

func _enter() -> void:
	print("=== PLAYER ENTERED DEAD STATE ===")
	print("Health: ", obj.health, " / ", obj.max_health)
	
	obj.change_animation("dead")
	# Goi coroutine doi 0.5s roi reset scene
	obj.set_detect_and_hurt_collsion(false)
	obj.velocity.x = 0
	defeat_screen_shown = false
	
	# Create timer to show defeat screen after death animation
	defeat_timer = Timer.new()
	defeat_timer.wait_time = 1.5
	defeat_timer.one_shot = true
	defeat_timer.process_mode = Node.PROCESS_MODE_ALWAYS  # Work even when paused!
	defeat_timer.timeout.connect(_on_defeat_timer_timeout)
	add_child(defeat_timer)
	defeat_timer.start()
	
func _on_defeat_timer_timeout():
	print("Defeat timer timeout!")
	if not defeat_screen_shown:
		defeat_screen_shown = true
		show_defeat_screen()
	
	if defeat_timer:
		defeat_timer.queue_free()
		defeat_timer = null

func _update(_delta: float) -> void:
	# Check if should turn off giant mode before showing defeat screen
	if obj.is_giant_mode:
		obj.inactive_giant_form()

func _exit():
	if defeat_timer:
		defeat_timer.queue_free()
		defeat_timer = null

func show_defeat_screen() -> void:
	print("=== SHOWING DEFEAT SCREEN ===")
	print("Scene tree: ", get_tree())
	print("Root: ", get_tree().root)
	
	# Load and show defeat screen
	var defeat_screen_scene = load("res://screens/game_screen/defeat_screen.tscn")
	if defeat_screen_scene:
		var defeat_screen = defeat_screen_scene.instantiate()
		if defeat_screen:
			# Add to root directly
			get_tree().root.add_child(defeat_screen)
			print("Defeat screen added to root! Total children: ", get_tree().root.get_child_count())
			
			# List all children in root for debugging
			print("--- Root children: ---")
			for i in get_tree().root.get_child_count():
				var child = get_tree().root.get_child(i)
				print("  [", i, "] ", child.name, " (", child.get_class(), ")")
		else:
			push_error("Failed to instantiate defeat_screen!")
	else:
		push_error("Failed to load defeat_screen.tscn!")
