extends Node2D

const APPEAR_SHADER = preload("res://resources/effects/gold_ash_dissolve.gdshader")
const APPEAR_SOUND_STREAM = preload("res://asset/sounds/king_crab_sound/cast.mp3")
const VISUAL_ARROW_SCENE = preload("res://scenes/ui/direction_arrow.tscn")

@onready var column_left: Node2D = $ColumnLeft
@onready var column_right: Node2D = $ColumnRight
@onready var enemies_group_1: Node2D = $EnemiesGroup1
@onready var enemies_group_2: Node2D = $EnemiesGroup2
@onready var enemies_group_3: Node2D = $EnemiesGroup3
@onready var active_area: Area2D = $ActiveGroup1Area2D

# State
var current_wave: int = 0
var active_enemies: int = 0
var is_triggered: bool = false
var audio_player: AudioStreamPlayer2D

func _ready() -> void:
	audio_player = AudioStreamPlayer2D.new()
	audio_player.stream = APPEAR_SOUND_STREAM
	audio_player.bus = "SFX"
	add_child(audio_player)

	# Initial State Setup
	_set_branch_active(column_right, true) # Right Column Visible & Blocking
	_set_branch_active(column_left, false) # Left Column Hidden
	_set_branch_active(enemies_group_1, false)
	_set_branch_active(enemies_group_2, false)
	_set_branch_active(enemies_group_3, false)
	
	if active_area:
		active_area.body_entered.connect(_on_trigger_entered)
	
	# Removed _set_initial_camera_limit from here to fix sequential bug

func _set_initial_camera_limit() -> void:
	var normal_cols = column_right.get_node("Normal")
	if normal_cols and normal_cols.get_child_count() > 0:
		var target_col = normal_cols.get_child(0)
		var limit_x = int(target_col.global_position.x)
		if GameManager.current_stage and GameManager.current_stage.has_method("lock_camera_limit"):
			GameManager.current_stage.lock_camera_limit(limit_x)
			print("[PlatformBoss02] Camera locked to X: ", limit_x)

func _on_trigger_entered(body: Node2D) -> void:
	if is_triggered: return
	if not (body is Player): return
		
	is_triggered = true
	print("[PlatformBoss02] Trap Triggered!")
	
	# Lock Camera NOW
	_set_initial_camera_limit()
	
	# 1. Close Entrance (Left Column)
	# Important: enable_physics_and_logic=true so collision works!
	_appear_node(column_left, true)
	
	# 2. Wait 2s
	if not is_inside_tree(): return
	var tree = get_tree()
	if tree:
		await tree.create_timer(2.0).timeout
	if not is_inside_tree(): return
	
	# 3. Start Wave 1
	_start_wave(1)

func _start_wave(wave_idx: int) -> void:
	print("[PlatformBoss02] Starting Wave: ", wave_idx)
	current_wave = wave_idx
	var group: Node2D = null
	match wave_idx:
		1: group = enemies_group_1
		2: group = enemies_group_2
		3: group = enemies_group_3
	
	if group:
		_appear_node(group, true)

func _appear_node(node: Node2D, enable_physics_and_logic: bool = false) -> void:
	# 1. Play Sound
	audio_player.play()
	
	# 2. Make visible but keep physics DISABLED for now to prevent AI from overwriting shader
	node.visible = true
	
	# 3. Apply Shader
	var sprites = _get_all_sprites(node)
	for sprite in sprites:
		_apply_appear_shader(sprite)
	
	# 4. Wait for effect to finish (1.0s)
	# Using an independent timer to ensure robust timing
	if not is_inside_tree(): return
	var tree = get_tree()
	if tree:
		await tree.create_timer(1.0).timeout
	if not is_inside_tree(): return
	
	# 5. Enable Logic/Physics
	# Only AFTER shader is done, enable AI. This prevents Walk state from swapping material.
	if enable_physics_and_logic:
		_set_group_processing(node, true)
		
		# Connect count logic
		if node.name.begins_with("EnemiesGroup"):
			_connect_enemy_death_signals(node)

func _disappear_node(node: Node2D) -> void:
	audio_player.play()
	var sprites = _get_all_sprites(node)
	
	# Start shader on all
	for sprite in sprites:
		_apply_disappear_shader(sprite)
	
	# Wait for finish
	if not is_inside_tree(): return
	var tree = get_tree()
	if tree:
		await tree.create_timer(1.0).timeout
	
	# Hide and Disable
	_set_branch_active(node, false)
	node.visible = false

func _connect_enemy_death_signals(group: Node2D) -> void:
	for child in group.get_children():
		if child is Node2D:
			if child.has_signal("tree_exited"):
				if not child.tree_exited.is_connected(_on_enemy_died):
					child.tree_exited.connect(_on_enemy_died)
					active_enemies += 1
	print("[PlatformBoss02] Wave enemies count: ", active_enemies)

func _on_enemy_died() -> void:
	active_enemies -= 1
	if active_enemies <= 0:
		print("[PlatformBoss02] Wave Cleared!")
		call_deferred("_handle_wave_completion")

func _handle_wave_completion() -> void:
	if current_wave == 1: _start_wave(2)
	elif current_wave == 2: _start_wave(3)
	elif current_wave == 3:
		current_wave = 4
		print("[PlatformBoss02] All Waves Cleared. Waiting 4s...")
		if not is_inside_tree(): return
		var tree = get_tree()
		if tree:
			await tree.create_timer(4.0).timeout
		if not is_inside_tree(): return
		_end_sequence()

func _end_sequence() -> void:
	active_enemies = 100 # Block triggers
	_disappear_node(column_left)
	_disappear_node(column_right)
	
	# Wait for disappear to finish before updating camera (visual cue)
	if not is_inside_tree(): return
	var tree = get_tree()
	if tree:
		await tree.create_timer(1.0).timeout
	
	if GameManager.current_stage and GameManager.current_stage.has_method("unlock_camera_limit"):
		GameManager.current_stage.unlock_camera_limit()
		print("[PlatformBoss02] Camera Unlocked")
		
		var arrow = VISUAL_ARROW_SCENE.instantiate()
		add_child(arrow)

# --- Helpers ---

func _set_branch_active(node: Node2D, active: bool) -> void:
	node.visible = active
	node.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED

func _set_group_processing(group: Node2D, enabled: bool) -> void:
	group.process_mode = Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED

func _get_all_sprites(node: Node) -> Array[CanvasItem]:
	var sprites: Array[CanvasItem] = []
	if (node is Sprite2D) or (node is AnimatedSprite2D):
		sprites.append(node)
	
	for child in node.get_children():
		sprites.append_array(_get_all_sprites(child))
	return sprites

func _apply_appear_shader(sprite: CanvasItem) -> void:
	var mat = ShaderMaterial.new()
	mat.shader = APPEAR_SHADER
	mat.set_shader_parameter("progress", 1.0)
	sprite.material = mat
	
	var tw = create_tween()
	tw.tween_method(func(val): 
		if is_instance_valid(sprite) and sprite.material == mat:
			mat.set_shader_parameter("progress", val)
	, 1.0, 0.0, 1.0)
	
	tw.tween_callback(func(): 
		if is_instance_valid(sprite):
			sprite.material = null
	)

func _apply_disappear_shader(sprite: CanvasItem) -> void:
	var mat = ShaderMaterial.new()
	mat.shader = APPEAR_SHADER
	mat.set_shader_parameter("progress", 0.0)
	sprite.material = mat
	
	var tw = create_tween()
	tw.tween_method(func(val): 
		if is_instance_valid(sprite) and sprite.material == mat:
			mat.set_shader_parameter("progress", val)
	, 0.0, 1.0, 1.0)
