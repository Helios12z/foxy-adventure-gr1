extends Node2D

@export var serpent_eel_scene: PackedScene
@export var golden_carp_scene: PackedScene

@export var fight_trigger_area: Area2D                      
@export var prewave_spawn_markers: Array[Marker2D] = []     
@export var boss_bg_marker: Marker2D                       
@export var boss_land_marker: Marker2D                      
@export var boss_intro_jump_height: float = 220.0        
@export var boss_parallax_layer: ParallaxLayer    

@onready var boss_hud: Control = $CanvasLayer/BossHUD
@onready var boss: CharacterBody2D = $World/WaterPrietest
@onready var boss_platform_controller: Node2D = $World/BossPlatformController
@onready var room_bound_point_a: Marker2D = $World/RoomBoundPointA
@onready var room_bound_point_b: Marker2D = $World/RoomBoundPointB
@onready var chest: Node2D = $World/Chest

@onready var ambient: AudioStreamPlayer2D = $Sound/Ambient
@onready var boss_entry_sfx: AudioStreamPlayer2D = get_node_or_null("Sound/BossEntry")

var _prewave_started: bool = false
var _prewave_enemies_left: int = 0
var _boss_intro_started: bool = false
var _boss_in_parallax: bool = false
var cutscene_controller: Node2D = null

func _enter_tree() -> void:
	GameManager.current_stage = self

func _ready() -> void:
	if not GameManager.respawn_at_portal():
		GameManager.respawn_at_checkpoint()

	ambient.play(2.0)

	var boss_defeated := GameManager.is_boss_defeated()

	if boss_defeated:
		_setup_boss_defeated_state()
	else:
		if fight_trigger_area:
			fight_trigger_area.monitoring = true
			fight_trigger_area.monitorable = true

			var player_body := get_node_or_null("World/Player")
			if player_body is PhysicsBody2D:
				fight_trigger_area.collision_mask = (player_body as PhysicsBody2D).collision_layer

		_setup_boss_alive_state()

func _process(_delta: float) -> void:
	if _boss_in_parallax and boss_bg_marker and boss and boss.get_parent() == boss_parallax_layer:
		var target_global := boss_bg_marker.global_position
		var parallax_transform := boss_parallax_layer.get_global_transform()
		var local_pos := parallax_transform.affine_inverse() * target_global
		boss.position = local_pos
		
func _on_boss_start_fight() -> void:
	boss_hud._on_boss_start_fighting()
	await get_tree().create_timer(0.75).timeout

func _on_boss_died() -> void:
	boss_platform_controller.return_platform_after_boss_dead()
	await get_tree().create_timer(2.25).timeout
	_spawn_chest()

func _on_fight_trigger_body_entered(body: Node) -> void:
	if not body.is_in_group("Player"):
		return
	if _prewave_started:
		return

	_prewave_started = true
	if fight_trigger_area:
		fight_trigger_area.monitoring = false

	boss_platform_controller.start_boss_intro()
	_spawn_prewave_enemies()

func _spawn_prewave_enemies() -> void:
	_prewave_enemies_left = 0

	var enemies: Array[Node2D] = [
		serpent_eel_scene.instantiate() as Node2D,
		serpent_eel_scene.instantiate() as Node2D,
		golden_carp_scene.instantiate() as Node2D,
		golden_carp_scene.instantiate() as Node2D
	]

	var world := get_node_or_null("World") as Node2D
	if world == null:
		world = self

	for i in range(enemies.size()):
		var enemy: Node2D = enemies[i]
		var marker: Marker2D = prewave_spawn_markers[i]

		if enemy == null or marker == null:
			continue

		world.add_child(enemy)

		enemy.visible = true
		if "modulate" in enemy:
			enemy.modulate = Color(1, 1, 1, 1)
		enemy.z_index = 0

		var spawn_pos := marker.global_position
		enemy.global_position = spawn_pos
		_register_prewave_enemy(enemy)


func _register_prewave_enemy(enemy: Node) -> void:
	_prewave_enemies_left += 1
	enemy.tree_exited.connect(_on_prewave_enemy_died.bind(enemy))

func _on_prewave_enemy_died(_enemy: Node) -> void:
	_prewave_enemies_left -= 1
	if _prewave_enemies_left <= 0:
		_start_boss_intro_jump()

func _start_boss_intro_jump() -> void:
	if _boss_intro_started:
		return
	_boss_intro_started = true

	var world := get_node("World") as Node2D

	var start_pos: Vector2 = boss.global_position
	if boss_bg_marker:
		start_pos = boss_bg_marker.global_position
	boss.global_position = start_pos

	var land_pos: Vector2 = boss.global_position
	if boss_land_marker:
		land_pos = boss_land_marker.global_position
	elif boss_platform_controller and "rect_platform" in boss_platform_controller:
		var rect_plat: Node2D = boss_platform_controller.rect_platform
		if rect_plat:
			land_pos = rect_plat.global_position

	var apex_y = min(start_pos.y, land_pos.y) - boss_intro_jump_height
	var apex_pos := Vector2(land_pos.x, apex_y)

	boss.set_physics_process(false)
	boss.change_animation("jump")

	var tw := create_tween()

	tw.tween_property(
		boss,
		"global_position",
		apex_pos,
		0.45
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	tw.tween_callback(func ():
		if boss_parallax_layer and boss.get_parent() == boss_parallax_layer and world:
			var gp := boss.global_position
			boss_parallax_layer.remove_child(boss)
			world.add_child(boss)
			boss.global_position = gp
			_boss_in_parallax = false 
	)

	tw.tween_property(
		boss,
		"global_position",
		land_pos,
		0.35
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	tw.finished.connect(func ():
		boss.change_animation("idle")
		boss.set_physics_process(false)
		# Start the cutscene after boss lands
		_trigger_cutscene_after_landing()
	)

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

	if chest.get_parent() == null:
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

	_place_boss_idle_in_background()

	if fight_trigger_area and not fight_trigger_area.body_entered.is_connected(_on_fight_trigger_body_entered):
		fight_trigger_area.body_entered.connect(_on_fight_trigger_body_entered)

	if not boss.boss_died.is_connected(_on_boss_died):
		boss.boss_died.connect(_on_boss_died)

	if not boss.start_fight.is_connected(_on_boss_start_fight):
		boss.start_fight.connect(_on_boss_start_fight)
		
	if not boss.into_phase2.is_connected(_on_boss_into_phase2):
		boss.into_phase2.connect(_on_boss_into_phase2)

func _place_boss_idle_in_background() -> void:
	if boss_bg_marker:
		var target_global := boss_bg_marker.global_position

		if boss_parallax_layer:
			var gp := target_global
			var old_parent := boss.get_parent()
			if old_parent:
				old_parent.remove_child(boss)
			boss_parallax_layer.add_child(boss)
			var parallax_transform := boss_parallax_layer.get_global_transform()
			var local_pos := parallax_transform.affine_inverse() * gp
			boss.position = local_pos
			_boss_in_parallax = true
		else:
			boss.global_position = target_global
			_boss_in_parallax = false

	boss.modulate.a = 1.0
	boss.set_physics_process(false)
	boss.change_animation("idle")

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
				
func _on_boss_into_phase2() -> void:
	pass

func _setup_cutscene() -> void:
	# Load the cutscene script
	var cutscene_script = load("res://scenes/cutscenes/water_priestess_awakening_cutscene.gd")
	if not cutscene_script:
		print("[Level] Failed to load cutscene script")
		return

	# Create cutscene controller
	cutscene_controller = Node2D.new()
	cutscene_controller.name = "WaterPriestessCutscene"
	cutscene_controller.set_script(cutscene_script)

	# Create trigger area (will be activated after boss lands)
	var trigger_area = Area2D.new()
	trigger_area.name = "CutsceneTrigger"
	trigger_area.collision_layer = 0
	trigger_area.collision_mask = 2  # Player layer
	trigger_area.monitoring = false  # Disabled initially
	trigger_area.monitorable = false

	# Create collision shape for trigger
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(400, 300)  # Large trigger area
	collision_shape.shape = shape
	trigger_area.add_child(collision_shape)

	# Position trigger area near the boss landing position
	if boss_land_marker:
		trigger_area.global_position = boss_land_marker.global_position
	else:
		trigger_area.global_position = boss.global_position

	# Add trigger as child BEFORE adding controller to scene
	cutscene_controller.add_child(trigger_area)

	# Now add controller to scene (this will call _ready)
	$World.add_child(cutscene_controller)

	# Wait for next frame, then set up properties
	await get_tree().process_frame

	# Set up cutscene controller properties directly
	cutscene_controller.boss = boss
	cutscene_controller.trigger_area = trigger_area
	cutscene_controller.cutscene_camera_zoom = 1.0

	print("[Level] Cutscene setup complete - Boss at: ", boss.global_position)
	print("[Level] Trigger area at: ", trigger_area.global_position)
	print("[Level] Trigger size: ", shape.size)

func _trigger_cutscene_after_landing() -> void:
	# Setup the cutscene if not already done
	if not cutscene_controller:
		_setup_cutscene()
		# Wait for setup to complete
		await get_tree().process_frame

	# Enable the trigger area
	if cutscene_controller and cutscene_controller.trigger_area:
		cutscene_controller.trigger_area.monitoring = true

		# Get player position and check if already in trigger area
		var player := get_tree().get_first_node_in_group("Player") as Node2D
		if player:
			var trigger_area := cutscene_controller.trigger_area as Area2D
			# Manually trigger if player is already close
			var distance := player.global_position.distance_to(trigger_area.global_position)
			if distance < 200:  # Within trigger range
				# Directly call the cutscene trigger
				cutscene_controller._on_trigger_area_body_entered(player)
				return

	print("[Level] Cutscene trigger enabled after boss landing")
