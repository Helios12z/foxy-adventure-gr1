extends Node2D

const APPEAR_SHADER = preload("res://resources/effects/gold_ash_dissolve.gdshader")
const APPEAR_SOUND_STREAM = preload("res://asset/sounds/king_crab_sound/cast.mp3")

@onready var column_left: Node2D = $ColumnLeft
@onready var column_right: Node2D = $ColumnRight
@onready var enemies_group_1: Node2D = get_node_or_null("EnemiesGroup1")
@onready var enemies_group_2: Node2D = get_node_or_null("EnemiesGroup2")
@onready var enemies_group_3: Node2D = get_node_or_null("EnemiesGroup3")
@onready var active_area: Area2D = $ActiveGroup1Area2D

# State
var current_wave: int = 0
var active_enemies_local: int = 0
var is_triggered: bool = false
var audio_player: AudioStreamPlayer2D

func _ready() -> void:
	audio_player = AudioStreamPlayer2D.new()
	audio_player.stream = APPEAR_SOUND_STREAM
	audio_player.bus = "SFX"
	add_child(audio_player)
	
	# Initial State
	_set_branch_active(column_right, true)
	_set_branch_active(column_left, false)
	
	if enemies_group_1: _set_branch_active(enemies_group_1, false)
	if enemies_group_2: _set_branch_active(enemies_group_2, false)
	if enemies_group_3: _set_branch_active(enemies_group_3, false)
	
	if active_area:
		active_area.body_entered.connect(_on_trigger_entered)
	
	# Removed _set_initial_camera_limit from here for sequential logic

func _set_initial_camera_limit() -> void:
	var normal_cols = column_right.get_node("Normal")
	if normal_cols and normal_cols.get_child_count() > 0:
		var target_col = normal_cols.get_child(0)
		var limit_x = int(target_col.global_position.x)
		if GameManager.current_stage and GameManager.current_stage.has_method("lock_camera_limit"):
			GameManager.current_stage.lock_camera_limit(limit_x)
			print("[WaterGoddessPlatform] Camera locked to X: ", limit_x)

func _on_trigger_entered(body: Node2D) -> void:
	if is_triggered: return
	if not (body is Player): return
	is_triggered = true
	print("[WaterGoddessPlatform] Trap Triggered!")
	
	# Lock Camera NOW
	_set_initial_camera_limit()
	
	# Close Entrance (Enabling logic for collision)
	_appear_node(column_left, true)
	
	# Wait 2s
	if not is_inside_tree(): return
	var tree = get_tree()
	if tree:
		await tree.create_timer(2.0).timeout
	if not is_inside_tree(): return
	
	_start_wave(1)

func _start_wave(idx: int) -> void:
	current_wave = idx
	print("[WaterGoddessPlatform] Starting Wave: ", idx)
	var group: Node2D = null
	match idx:
		1: group = enemies_group_1
		2: group = enemies_group_2
		3: group = enemies_group_3
	
	if group:
		_appear_node(group, true)
		
		# For Wave 3 (Pearl Fairies), start global check regardless of local count
		if idx == 3:
			_start_checking_clear()

func _appear_node(node: Node2D, enable_logic: bool = false) -> void:
	audio_player.play()
	node.visible = true
	
	var sprites = _get_all_sprites(node)
	for sprite in sprites:
		_apply_appear_shader(sprite)
	
	# Wait 1s
	if not is_inside_tree(): return
	var tree = get_tree()
	if tree:
		await tree.create_timer(1.0).timeout
	if not is_inside_tree(): return
	
	if enable_logic:
		_set_group_processing(node, true)
		if node.name.begins_with("EnemiesGroup"):
			_connect_enemy_death_signals(node)

func _disappear_node(node: Node2D) -> void:
	audio_player.play()
	var sprites = _get_all_sprites(node)
	for sprite in sprites:
		_apply_disappear_shader(sprite)
	
	# Wait 1s
	if not is_inside_tree(): return
	var tree = get_tree()
	if tree:
		await tree.create_timer(1.0).timeout
	
	_set_branch_active(node, false)
	node.visible = false

func _connect_enemy_death_signals(group: Node2D) -> void:
	for child in group.get_children():
		if child is Node2D and child.has_signal("tree_exited"):
			if not child.tree_exited.is_connected(_on_enemy_died):
				child.tree_exited.connect(_on_enemy_died)
				active_enemies_local += 1

func _on_enemy_died() -> void:
	active_enemies_local -= 1
	if active_enemies_local <= 0:
		print("[WaterGoddessPlatform] Local Group Cleared")
		_handle_wave_completion()

func _handle_wave_completion() -> void:
	if current_wave == 1: _start_wave(2)
	elif current_wave == 2: _start_wave(3)
	# Wave 3 handled by poller

func _start_checking_clear() -> void:
	var t = Timer.new()
	t.wait_time = 1.0
	t.autostart = true
	t.timeout.connect(_check_arena_clear)
	add_child(t)

func _check_arena_clear() -> void:
	if current_wave != 3: return
	
	var min_x = column_left.global_position.x - 300
	var max_x = column_right.global_position.x + 300
	
	var count = 0
	var enemies = get_tree().get_nodes_in_group("Enemy")
	
	if enemies.size() == 0:
		var root = get_tree().current_scene
		var nodes = root.find_children("*", "EnemyCharacter", true, false)
		for n in nodes:
			if is_instance_valid(n) and not n.is_queued_for_deletion():
				if n.global_position.x > min_x and n.global_position.x < max_x:
					count += 1
	else:
		for n in enemies:
			if is_instance_valid(n) and not n.is_queued_for_deletion():
				if n.global_position.x > min_x and n.global_position.x < max_x:
					count += 1
	
	if count == 0:
		print("[WaterGoddessPlatform] Arena Cleared (Wave 3)!")
		current_wave = 4
		
		# End Sequence
		print("[WaterGoddessPlatform] Waiting 4s...")
		if not is_inside_tree(): return
		var tree = get_tree()
		if tree:
			await tree.create_timer(4.0).timeout
		if not is_inside_tree(): return
		_end_sequence()

func _end_sequence() -> void:
	_disappear_node(column_left)
	_disappear_node(column_right)
	
	if not is_inside_tree(): return
	var tree = get_tree()
	if tree:
		await tree.create_timer(1.0).timeout
	
	if GameManager.current_stage and GameManager.current_stage.has_method("unlock_camera_limit"):
		GameManager.current_stage.unlock_camera_limit()
		print("[WaterGoddessPlatform] Camera Unlocked")

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
