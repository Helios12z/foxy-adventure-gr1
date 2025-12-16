extends Node2D

@onready var boss_hud: Control = $CanvasLayer/BossHUD
@onready var boss: CharacterBody2D = $World/KingCrab
@onready var boss_platform_controller: Node2D = $World/BossPlatformController
@onready var room_bound_point_b: Marker2D = $World/BossPlatformController/DiamondPlatform/RoomBoundPointB
@onready var room_bound_point_a: Marker2D = $World/BossPlatformController/DiamondPlatform/RoomBoundPointA
@onready var chest: Node2D = $World/Chest

@onready var ambient: AudioStreamPlayer2D = $Sound/Ambient

var cutscene_controller: Node2D = null

func _enter_tree() -> void:
	GameManager.current_stage = self

func _ready() -> void:
	GameManager.is_scene_boss = true
	GameManager.inventory_system.heal_potions = 3
	GameManager.inventory_system.heal_potion_changed.emit(3)
	if not GameManager.respawn_at_portal():
		GameManager.respawn_at_checkpoint()

	ambient.play(2.0)

	var boss_defeated := GameManager.is_boss_defeated()

	if boss_defeated:
		_setup_boss_defeated_state()
	else:
		_setup_boss_alive_state()
		_setup_cutscene()

func _process(delta: float) -> void:
	if GameManager.player.health <= 0:
		GameManager.inventory_system.heal_potions = 3

func _on_boss_start_fight() -> void:
	await get_tree().create_timer(0.75).timeout
	boss_platform_controller.start_boss_intro()

func _on_boss_died() -> void:
	boss_platform_controller.return_platform_after_boss_dead()
	
	var fall_time = boss_platform_controller.rise_time if boss_platform_controller.has_method("get") else 1.0
	await get_tree().create_timer(fall_time + 1.25).timeout
	_spawn_chest()
	
func _on_complete_moving_up() -> void:
	boss.seen_player = true 
	boss_hud._on_boss_start_fighting()
	if boss.phase_1 and not boss.phase_1.playing:
		boss.phase_1.play()
	
func _spawn_chest() -> void:
	if chest == null:
		return
	
	chest.visible = true 
	_set_chest_collision(chest, true)

	var feet := chest.get_node("Feet") as Marker2D

	var a = room_bound_point_a.global_position
	var b = room_bound_point_b.global_position

	var spawn_x = (a.x + b.x) * 0.5
	var ground_y = a.y

	var target_y = ground_y - feet.position.y
	var start_y = target_y - 300.0

	chest.global_position = Vector2(spawn_x, start_y)
	add_child(chest)

	var tw := create_tween()
	tw.tween_property(
		chest,
		"global_position:y",
		target_y,
		1.0
	).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
func _set_chest_collision(root: Node, enabled: bool) -> void:
	if root == null:
		return

	for child in root.get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.disabled = not enabled
		if child is Area2D:
			child.monitoring = enabled
			child.monitorable = enabled
		if child.get_child_count() > 0:
			_set_chest_collision(child, enabled)
			
func _setup_boss_alive_state() -> void:
	if chest:
		chest.visible = false
		_set_chest_collision(chest, false)

	boss_hud.set_boss(boss)
	
	if not boss.start_fight.is_connected(_on_boss_start_fight):
		boss.start_fight.connect(_on_boss_start_fight)

	if not boss.boss_died.is_connected(_on_boss_died):
		boss.boss_died.connect(_on_boss_died)
		
	if not boss_platform_controller.complete_moving_up.is_connected(_on_complete_moving_up):
		boss_platform_controller.complete_moving_up.connect(_on_complete_moving_up)


func _setup_boss_defeated_state() -> void:
	if is_instance_valid(boss):
		boss.queue_free()

	if boss_hud and boss_hud.has_method("reset"):
		boss_hud.reset()

	boss_platform_controller.setup_after_boss_dead_state()

	if chest:
		chest.visible = true

		var chest_opened := GameManager.is_chest_opened()
		_set_chest_collision(chest, not chest_opened)

		var feet := chest.get_node("Feet") as Marker2D
		var a = room_bound_point_a.global_position
		var b = room_bound_point_b.global_position

		var spawn_x = (a.x + b.x) * 0.5
		var ground_y = a.y
		var target_y = ground_y - feet.position.y

		chest.global_position = Vector2(spawn_x, target_y)

		if chest.has_node("AnimatedSprite2D"):
			var anim := chest.get_node("AnimatedSprite2D") as AnimatedSprite2D
			if chest_opened:
				anim.play("open")

func _setup_cutscene() -> void:
	# Load the cutscene script
	var cutscene_script = load("res://scenes/cutscenes/king_crab_awakening_cutscene.gd")
	if not cutscene_script:
		print("[Level] Failed to load cutscene script")
		return

	# Create trigger area FIRST
	var trigger_area = Area2D.new()
	trigger_area.name = "CutsceneTrigger"
	trigger_area.collision_layer = 0
	trigger_area.collision_mask = 2  # Player layer
	trigger_area.monitoring = true
	trigger_area.monitorable = false

	# Create collision shape for trigger
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(400, 300)  # Larger trigger area
	collision_shape.shape = shape
	trigger_area.add_child(collision_shape)

	# Position trigger area in front of the boss
	trigger_area.global_position = boss.global_position + Vector2(-200, 0)

	# Create cutscene controller
	cutscene_controller = Node2D.new()
	cutscene_controller.name = "KingCrabCutscene"
	cutscene_controller.set_script(cutscene_script)

	# Add trigger as child BEFORE adding controller to scene
	cutscene_controller.add_child(trigger_area)

	# Now add controller to scene (this will call _ready)
	$World.add_child(cutscene_controller)

	# Wait for next frame, then set up properties
	await get_tree().process_frame

	# Set up cutscene controller properties directly
	cutscene_controller.boss = boss
	cutscene_controller.trigger_area = trigger_area
	# Optional: Adjust zoom here if you want (1.2 = less zoom, 1.5 = more zoom, 2.0 = very close)
	cutscene_controller.cutscene_camera_zoom = 1.0

	print("[Level] Cutscene setup complete - Boss at: ", boss.global_position)
	print("[Level] Trigger area at: ", trigger_area.global_position)
	print("[Level] Trigger size: ", shape.size)   
