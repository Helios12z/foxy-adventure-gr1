extends Node2D

@export var serpent_eel_scene: PackedScene
@export var golden_carp_scene: PackedScene

@export var fight_trigger_area: Area2D
@export var prewave_spawn_markers: Array[Marker2D] = []
@export var boss_bg_marker: Marker2D
@export var boss_land_marker: Marker2D
@export var boss_intro_jump_height: float = 220.0
@export var boss_parallax_layer: ParallaxLayer
@export var monster_bg_spawn_markers: Array[Marker2D] = []
@export var monster_land_markers: Array[Marker2D] = []
@export var monster_intro_jump_height: float = 150.0    

@onready var boss_hud: Control = $CanvasLayer/BossHUD
@onready var boss: CharacterBody2D = $World/WaterPrietest
@onready var frost_guardian: CharacterBody2D = $World/FrostGuardian
@onready var boss_platform_controller: Node2D = $World/BossPlatformController
@onready var room_bound_point_a: Marker2D = $World/RoomBoundPointA
@onready var room_bound_point_b: Marker2D = $World/RoomBoundPointB
@onready var chest: Node2D = $World/Chest

@onready var ambient: AudioStreamPlayer2D = $Sound/Ambient
@onready var boss_entry_sfx: AudioStreamPlayer2D = get_node_or_null("Sound/BossEntry")
@onready var craking: AudioStreamPlayer2D = $Sound/Craking

var _prewave_started: bool = false
var _prewave_enemies_left: int = 0
var _boss_intro_started: bool = false
var _boss_in_parallax: bool = false
var _frost_guardian_defeated: bool = false
var cutscene_controller: Node2D = null
var _spawned_monsters: Array[Node2D] = []
var _monsters_in_parallax: Array[Node2D] = []

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
		if fight_trigger_area:
			fight_trigger_area.monitoring = true
			fight_trigger_area.monitorable = true

			var player_body := get_node_or_null("World/Player")
			if player_body is PhysicsBody2D:
				fight_trigger_area.collision_mask = (player_body as PhysicsBody2D).collision_layer

		_setup_boss_alive_state()

func _process(_delta: float) -> void:
	if GameManager.player.health <= 0:
		GameManager.inventory_system.heal_potions = 3
	if _boss_in_parallax and boss_bg_marker and boss and boss.get_parent() == boss_parallax_layer:
		var target_global := boss_bg_marker.global_position
		var parallax_transform := boss_parallax_layer.get_global_transform()
		var local_pos := parallax_transform.affine_inverse() * target_global
		boss.position = local_pos
		
func _on_boss_start_fight() -> void:
	boss_hud._on_boss_start_fighting()
	await get_tree().create_timer(0.75).timeout

func _on_boss_died() -> void:
	# Platform transition will now happen after death dialog completes
	# See dead.gd -> _on_dialogue_finished()
	await get_tree().create_timer(2.25).timeout
	_spawn_chest()

func _on_frost_guardian_died() -> void:
	_frost_guardian_defeated = true

	boss_hud.visible = false
	boss_hud.reset()
	boss_hud.set_boss(boss)
	boss_hud.get_node("BossHealthLabel").text = "GUARDIAN OF THE WATER PALACE"

	await get_tree().create_timer(1.0).timeout
	_start_boss_intro_jump()

func _on_fight_trigger_body_entered(body: Node) -> void:
	if not body.is_in_group("Player"):
		return
	if _prewave_started:
		return

	_prewave_started = true
	if fight_trigger_area:
		fight_trigger_area.monitoring = false

	boss_platform_controller.start_boss_intro()
	_start_monster_intro_jump()

func _register_prewave_enemy(enemy: Node) -> void:
	_prewave_enemies_left += 1
	enemy.tree_exited.connect(_on_prewave_enemy_died.bind(enemy))

func _on_prewave_enemy_died(_enemy: Node) -> void:
	_prewave_enemies_left -= 1
	if _prewave_enemies_left <= 0:
		_start_frost_guardian_encounter()

func _spawn_monsters_in_background() -> void:
	_spawned_monsters.clear()
	_monsters_in_parallax.clear()

	var enemies: Array[Node2D] = [
		serpent_eel_scene.instantiate() as Node2D,
		serpent_eel_scene.instantiate() as Node2D,
		golden_carp_scene.instantiate() as Node2D,
		golden_carp_scene.instantiate() as Node2D
	]

	for i in range(enemies.size()):
		var enemy: Node2D = enemies[i]
		if i >= monster_bg_spawn_markers.size():
			break

		var marker: Marker2D = monster_bg_spawn_markers[i]

		if enemy == null or marker == null:
			continue

		if boss_parallax_layer:
			var target_global := marker.global_position
			boss_parallax_layer.add_child(enemy)
			var parallax_transform := boss_parallax_layer.get_global_transform()
			var local_pos := parallax_transform.affine_inverse() * target_global
			enemy.position = local_pos
			_monsters_in_parallax.append(enemy)
		else:
			var world := get_node_or_null("World") as Node2D
			if world:
				world.add_child(enemy)
				enemy.global_position = marker.global_position

		enemy.visible = true
		if "modulate" in enemy:
			enemy.modulate = Color(1, 1, 1, 1)

		if enemy.has_method("set_physics_process"):
			enemy.set_physics_process(false)
		if enemy.has_method("change_animation"):
			enemy.change_animation("idle")

		_spawned_monsters.append(enemy)

func _start_monster_intro_jump() -> void:
	if _spawned_monsters.is_empty():
		return

	var world := get_node("World") as Node2D

	for i in range(_spawned_monsters.size()):
		var enemy: Node2D = _spawned_monsters[i]
		if enemy == null:
			continue

		var land_marker: Marker2D = null
		if i < monster_land_markers.size():
			land_marker = monster_land_markers[i]

		if land_marker == null:
			continue

		var start_pos: Vector2 = enemy.global_position
		var land_pos: Vector2 = land_marker.global_position

		var apex_y = min(start_pos.y, land_pos.y) - monster_intro_jump_height
		var apex_pos := Vector2(land_pos.x, apex_y)

		if enemy.has_method("set_physics_process"):
			enemy.set_physics_process(false)
		if enemy.has_method("change_animation"):
			enemy.change_animation("jump")

		if boss_parallax_layer and enemy.get_parent() == boss_parallax_layer:
			var gp := enemy.global_position
			boss_parallax_layer.remove_child(enemy)
			world.add_child(enemy)
			enemy.global_position = gp
			_monsters_in_parallax.erase(enemy)

		var tw := create_tween()
		tw.tween_property(
			enemy,
			"global_position",
			apex_pos,
			0.7
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		tw.tween_property(
			enemy,
			"global_position",
			land_pos,
			0.7
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

		tw.finished.connect(func ():
			if enemy.has_method("change_animation"):
				enemy.change_animation("idle")
			if enemy.has_method("set_physics_process"):
				enemy.set_physics_process(true)
			_register_prewave_enemy(enemy)
		)

func _start_frost_guardian_encounter() -> void:
	boss_hud.visible = true
	frost_guardian.start_appearing.emit()

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

	frost_guardian.visible = true
	frost_guardian.collision_shape_2d.disabled = true
	frost_guardian.attack_collision_shape_2d.disabled = true
	frost_guardian.hurt_collision_shape_2d.disabled = true
	frost_guardian.hit_collision_shape_2d.disabled = true

	if not frost_guardian.boss_died.is_connected(_on_frost_guardian_died):
		frost_guardian.boss_died.connect(_on_frost_guardian_died)

	boss_hud.set_boss(frost_guardian)
	boss_hud.get_node("BossHealthLabel").text = "GOLEM OF THE WATER PALACE"
	boss_hud.visible = false

	_place_boss_idle_in_background()
	_spawn_monsters_in_background()

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
	# Show blue glowing aura during phase 2
	if boss and boss.has_node("Phase2Aura"):
		var aura = boss.get_node("Phase2Aura")
		if aura is PointLight2D:
			aura.visible = true

			# Create a subtle pulsing effect for the aura
			var tween = create_tween()
			tween.set_loops()
			tween.tween_property(aura, "energy", 1.5, 1.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
			tween.tween_property(aura, "energy", 0.8, 1.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _setup_cutscene() -> void:
	# Load the cutscene script
	var cutscene_script = load("res://scenes/cutscenes/water_priestess_awakening_cutscene.gd")
	if not cutscene_script:
		print("[Level] Failed to load cutscene script")
		return

	cutscene_controller = Node2D.new()
	cutscene_controller.name = "WaterPriestessCutscene"
	cutscene_controller.set_script(cutscene_script)

	var trigger_area = Area2D.new()
	trigger_area.name = "CutsceneTrigger"
	trigger_area.collision_layer = 0
	trigger_area.collision_mask = 2  
	trigger_area.monitoring = false  
	trigger_area.monitorable = false

	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(400, 300) 
	collision_shape.shape = shape
	trigger_area.add_child(collision_shape)

	if boss_land_marker:
		trigger_area.global_position = boss_land_marker.global_position
	else:
		trigger_area.global_position = boss.global_position

	cutscene_controller.add_child(trigger_area)

	$World.add_child(cutscene_controller)

	await get_tree().process_frame

	cutscene_controller.boss = boss
	cutscene_controller.trigger_area = trigger_area
	cutscene_controller.cutscene_camera_zoom = 1.0

func _trigger_cutscene_after_landing() -> void:
	if not cutscene_controller:
		_setup_cutscene()
		await get_tree().process_frame

	if cutscene_controller and cutscene_controller.trigger_area:
		cutscene_controller.trigger_area.monitoring = true

		var player := get_tree().get_first_node_in_group("Player") as Node2D
		if player:
			var trigger_area := cutscene_controller.trigger_area as Area2D
			var distance := player.global_position.distance_to(trigger_area.global_position)
			if distance < 200: 
				cutscene_controller._on_trigger_area_body_entered(player)
				return
