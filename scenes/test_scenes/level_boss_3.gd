extends Node2D
@onready var boss_hud: Control = $CanvasLayer/BossHUD
@onready var boss: CharacterBody2D = $Boss3



func _enter_tree() -> void:
	GameManager.current_stage = self

func _ready() -> void:
	# Try to respawn at portal (door) first
	GameManager.is_scene_boss = true
	GameManager.inventory_system.heal_potions = 3
	GameManager.inventory_system.heal_potion_changed.emit(3)
	var spawned_at_portal = GameManager.respawn_at_portal()

	if not spawned_at_portal:
		GameManager.respawn_at_checkpoint()

	# Don't lock player movement at start - let boss intro handle it
	# if GameManager.player:
	#	GameManager.player.set_can_move(false)
	#	print("[Boss3 Level] Player locked from start")

	# Ensure player always respawns at the entrance door during boss fight
	var entrance_door = get_node_or_null("Teleport")
	if entrance_door and is_instance_valid(entrance_door):
		# Save a checkpoint at the entrance door position for respawning
		if spawned_at_portal and GameManager.player:
			# Player just entered through door - save checkpoint here
			var door_checkpoint_id = "boss3_entrance"
			GameManager.current_checkpoint_id = door_checkpoint_id
			GameManager.save_checkpoint(door_checkpoint_id)
			GameManager.save_checkpoint_data()
			print("[Boss3 Level] Saved entrance door checkpoint at: ", entrance_door.global_position)

			# Fade out the entrance door after teleportation
			_fade_entrance_door(entrance_door)

	_setup_boss_alive_state()
	_setup_camera_for_boss3()

	# Fade out the Door node AFTER scene is fully loaded and visible
	if spawned_at_portal:
		var door_node = get_node_or_null("Door")
		if door_node and is_instance_valid(door_node):
			# Wait for loading screen to finish and scene to be visible
			await get_tree().create_timer(2.0).timeout
			print("[Boss3 Level] Fading out Door node after arrival")
			_fade_entrance_door(door_node)

func _process(delta: float) -> void:
	if GameManager.player.health <= 0:
		GameManager.inventory_system.heal_potions = 3

func _setup_boss_alive_state() -> void:
	boss_hud.set_boss(boss)
	print("we set boss")

	# Connect to boss intro_finished signal to trigger dialogue instead of starting fight
	if not boss.intro_finished.is_connected(_on_boss_intro_finished):
		boss.intro_finished.connect(_on_boss_intro_finished)

func _on_boss_intro_finished() -> void:
	print("[Level Boss 3] Boss intro finished! Starting dialogue...")

	# Lock player during dialogue
	if GameManager.player:
		GameManager.player.set_can_move(false)
		print("[Boss3 Level] Player locked for dialogue")

	# Keep boss invulnerable during dialogue
	if boss:
		boss.is_invulnerable = true
		print("[Boss3 Level] Boss invulnerable during dialogue")

	# Start the Water Goddess awakening dialogue
	Dialogic.start("water_goddess_awakening")
	# Wait for dialogue to finish before starting fight
	await Dialogic.timeline_ended
	print("[Level Boss 3] Dialogue finished! Starting fight...")

	# Re-enable player movement
	if GameManager.player:
		GameManager.player.set_can_move(true)
		print("[Level Boss 3] Player movement enabled")

	# Start the boss fight (this will initialize FSM and make boss vulnerable)
	if boss and boss.has_method("start_boss_fight"):
		boss.start_boss_fight()
		print("[Level Boss 3] Boss fight started!")
	else:
		# Fallback for older boss scripts
		if boss:
			boss.is_invulnerable = false
			print("[Level Boss 3] Boss vulnerable (fallback)")

	boss_hud._on_boss_start_fighting()
	print("[Level Boss 3] HUD visible now: ", boss_hud.visible)

func _setup_camera_for_boss3() -> void:
	# Use Phase3Camera for the whole level instead of player's camera
	var phase3_camera = get_tree().get_first_node_in_group("Phase3Camera")
	if phase3_camera and phase3_camera.has_method("activate"):
		print("[Level Boss 3] Activating Phase3Camera for entire level...")
		var player_node = get_tree().get_first_node_in_group("Player")
		if player_node:
			phase3_camera.activate(player_node)
			print("[Level Boss 3] Phase3Camera activated successfully")
		else:
			print("[Level Boss 3] ERROR: Player not found")
	else:
		print("[Level Boss 3] WARNING: Phase3Camera not found, using player camera as fallback")
		# Fallback to old behavior
		var player_node = get_tree().get_first_node_in_group("Player")
		if not player_node:
			return

		var camera = player_node.get_node_or_null("Camera2D")
		if not camera:
			return

		camera.zoom = Vector2(1.3, 1.3)
		camera.offset = Vector2(0, 50)
		camera.limit_left = -100
		camera.limit_right = 700
		camera.limit_top = -1000
		camera.limit_bottom = -200
		print("[Level Boss 3] Player camera adjusted with limits for boss fight")

func _setup_boss_defeated_state() -> void:
	if is_instance_valid(boss):
		boss.queue_free()

	if boss_hud and boss_hud.has_method("reset"):
		boss_hud.reset()

## Fade out the entrance door after player teleports in
func _fade_entrance_door(door: Node2D) -> void:
	if not door:
		return

	# Find the sprite or animated sprite in the door
	var sprite = null
	for child in door.get_children():
		if child is Sprite2D or child is AnimatedSprite2D:
			sprite = child
			break

	if not sprite:
		# Try to get the door's own sprite if it has one
		if door is Sprite2D or door is AnimatedSprite2D:
			sprite = door

	if sprite:
		# Create fade out tween
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 1.5)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT)

		print("[Boss3 Level] Fading out entrance door")
	else:
		print("[Boss3 Level] Warning: Could not find sprite to fade in door")
