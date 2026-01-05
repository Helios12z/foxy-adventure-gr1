extends BaseCharacter

signal health_changed(current: float, max_health: float)
signal boss_died
signal into_phase2
signal start_fight

@export var roll_peak_height: float = 30.0
@export var atk1_damage: int = 25
@export var atk2_damage: int = 32
@export var atk3_damage: int = 40
@export var atk_super_damage: int = 45
@export var max_health_boss: int = 1000
@export var boss_jump_speed: float = 500.0     
@export var attack_range: float = 140.0
@export var move_speed: float = 80.0
@export var surf_speed: float = 100.0    
@export var air_horizontal_speed: float = 60.0
@export var max_fall_speed: float = 1200.0      
@export var phase2_threshold_ratio: float = 0.6
@export var roll_speed: float = 100.0
@export var roll_distance: float = 160.0
@export var atk1_windup_time: float = 1.25
@export var atk2_windup_time: float = 1.0
@export var atk3_windup_time: float = 0.75
@export var atk_super_windup_time: float = 0.75
@export var atk_air_windup_time: float = 0.5
@export var defend_range: float = 80.0
@export var defend_cooldown: float = 7.0
@export var attack_prepare_time: float = 2.5
@export var roll_escape_distance: float = 35.0
@export var roll_same_level_threshold: float = 32.0
@export var roll_cooldown: float = 7.0  

@export var retaliate_damage_window_seconds: float = 4.0 
@export var retaliate_combo_hits: int = 8 

@export var bound_point_a: Node2D
@export var bound_point_b: Node2D

# Platform jumping system
@export var jump_detection_range: float = 300.0
@export var max_jump_distance: float = 200.0
@export var jump_height_tolerance: float = 100.0

var can_attack: bool = true
var attack_cooldown_timer: float = 0.0
var can_defend: bool = true
var defend_cooldown_timer: float = 0.0
var can_roll: bool = true
var roll_cooldown_timer: float = 0.0
var state_transition_cooldown: float = 0.0
var _phase2_transition_running: bool = false
var _original_time_scale: float = 1.0

var jump_markers: Array[JumpMarker2D] = []
var current_jump_marker: JumpMarker2D = null
var target_jump_marker: JumpMarker2D = null

@onready var atk_1_hit_area_2d: HitArea2D = $Direction/Atk1HitArea2D
@onready var atk_2_hit_area_2d: HitArea2D = $Direction/Atk2HitArea2D
@onready var atk_2_hit_area_2d_2: HitArea2D = $Direction/Atk2HitArea2D2
@onready var atk_3_hit_area_2d: HitArea2D = $Direction/Atk3HitArea2D
@onready var atk_super_hit_area_2d: HitArea2D = $Direction/AtkSuperHitArea2D

@onready var animated_sprite_2d: AnimatedSprite2D = $Direction/AnimatedSprite2D

@onready var atk1_collision_shape_2d: CollisionShape2D = $Direction/Atk1HitArea2D/CollisionShape2D
@onready var atk2_collision_shape_2d_right: CollisionShape2D = $Direction/Atk2HitArea2D/CollisionShape2D
@onready var atk2_collision_shape_2d_left: CollisionShape2D = $Direction/Atk2HitArea2D2/CollisionShape2D
@onready var atk3_collision_shape_2d: CollisionShape2D = $Direction/Atk3HitArea2D/CollisionShape2D
@onready var atk_super_collision_shape_2d: CollisionShape2D = $Direction/AtkSuperHitArea2D/CollisionShape2D
@onready var hit_collision_shape_2d: CollisionShape2D = $Direction/HitArea2D/CollisionShape2D
@onready var hurt_collision_shape_2d: CollisionShape2D = $Direction/HurtArea2D/CollisionShape2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var attack_effect: AnimatedSprite2D = $Direction/AttackEffect

@onready var camera: Camera2D = get_tree().get_first_node_in_group("Camera")

@onready var phase_1: AudioStreamPlayer2D = $Sound/Phase1
@onready var phase_2_intro: AudioStreamPlayer2D = $Sound/Phase2Intro
@onready var phase_2: AudioStreamPlayer2D = $Sound/Phase2
@onready var slash: AudioStreamPlayer2D = $Sound/Slash
@onready var water_slash: AudioStreamPlayer2D = $Sound/WaterSlash
@onready var jump_sound: AudioStreamPlayer2D = $Sound/Jump
@onready var roll: AudioStreamPlayer2D = $Sound/Roll
@onready var defend: AudioStreamPlayer2D = $Sound/Defend
@onready var phase_2_talk: AudioStreamPlayer2D = $Sound/Phase2Talk
@onready var phase_2_aura: PointLight2D = $Phase2Aura

var seen_player: bool = false
var _flash_tw: Tween
var in_phase2: bool = false
var _recent_damage_times: PackedFloat32Array = []
var level_bounds: Rect2
var in_dialogue: bool = false
var _aura_tw: Tween

func _ready() -> void:
	movement_speed = 0.0
	velocity = Vector2.ZERO

	max_health = max_health_boss
	health = max_health

	super._ready()
	
	atk_1_hit_area_2d.damage = atk1_damage
	atk_2_hit_area_2d.damage = atk2_damage
	atk_2_hit_area_2d_2.damage = atk2_damage
	atk_3_hit_area_2d.damage = atk3_damage
	atk_super_hit_area_2d.damage = atk_super_damage

	_init_hurt_area()
	_update_level_bounds_from_markers()
	_init_jump_markers()
	_disable_hit_collisionshape()
	
	phase_2_intro.finished.connect(_on_phase_2_intro_finished)

	fsm = FSM.new(self, $States, $States/Idle)
	
func _disable_hit_collisionshape()->void:
	atk1_collision_shape_2d.disabled = true
	atk2_collision_shape_2d_left.disabled = true
	atk2_collision_shape_2d_right.disabled = true
	atk3_collision_shape_2d.disabled = true
	if atk_super_collision_shape_2d:
		atk_super_collision_shape_2d.disabled = true 

func _physics_process(delta: float) -> void:
	if not in_dialogue:
		update_defend_cooldown(delta)
		update_roll_cooldown(delta)
		update_attack_cooldown(delta)
		update_state_transition_cooldown(delta)
		_detect_player()

		if fsm.current_state == fsm.states.walk or fsm.current_state == fsm.states.idle or fsm.current_state == fsm.states.atk_1 or fsm.current_state == fsm.states.surf:
			_update_facing()

		_check_player_attack_input()

	super._physics_process(delta)

	if not in_dialogue:
		_keep_inside_room_and_avoid_fall()

		if fsm.current_state == fsm.states.roll or fsm.current_state == fsm.states.defend:
			animated_sprite_2d.speed_scale = 1.0

		print(fsm.current_state)

func _init_hurt_area() -> void:
	if has_node("Direction/HurtArea2D"):
		var hurt_area = $Direction/HurtArea2D
		hurt_area.hurt.connect(_on_hurt_area_2d_hurt)

func _on_hurt_area_2d_hurt(_dir: Vector2, damage: int) -> void:
	var on_ground = (
			fsm.current_state == fsm.states.idle
			or fsm.current_state == fsm.states.walk
			or fsm.current_state == fsm.states.surf
		)

	if _phase2_transition_running or in_dialogue:
		return

	if fsm.current_state == fsm.states.roll:
		return

	_note_damage_hit()

	if _took_consecutive_damage():
		var choice := randf()
		if choice < 0.7:
			fsm.change_state(fsm.states.defend)
		else:
			fsm.change_state(fsm.states.roll)
		_recent_damage_times.clear()
		return

	var should_block := false
	if fsm.current_state == fsm.states.defend:
		should_block = fsm.current_state.should_block_damage(_dir)

	if should_block:
		return

	take_damage(damage)
	emit_signal("health_changed", health, max_health)

	if health <= 0.0:
		if fsm and fsm.current_state != fsm.states.dead:
			_hide_phase2_aura()
			emit_signal("boss_died")
			fsm.change_state(fsm.states.dead)
			GameManager.mark_boss_defeated()
		return

	if not in_phase2 and health <= max_health * phase2_threshold_ratio:
		fsm.change_state(fsm.states.cast_into_phase_2)
		_start_phase2_transition()
		return

	if on_ground:
		fsm.change_state(fsm.states.hurt)
	else: 
		flash_hurt()

func flash_hurt(duration := 0.25, blinks := 3, color := Color(1, 0.2, 0.2, 1)) -> void:
	var mat := animated_sprite_2d.material as ShaderMaterial
	if mat == null:
		return

	mat.set_shader_parameter("flash_color", color)
	mat.set_shader_parameter("flash_amount", 0.0)

	if is_instance_valid(_flash_tw):
		_flash_tw.kill()

	_flash_tw = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var step := duration / float(blinks * 2)
	for i in blinks:
		_flash_tw.tween_property(mat, "shader_parameter/flash_amount", 1.0, step)
		_flash_tw.tween_property(mat, "shader_parameter/flash_amount", 0.0, step)

func _now_secs() -> float:
	return Time.get_ticks_msec() / 1000.0

func _prune_damage_times(now_secs: float) -> void:
	while _recent_damage_times.size() > 0 and now_secs - _recent_damage_times[0] > retaliate_damage_window_seconds:
		_recent_damage_times.remove_at(0)

func _note_damage_hit() -> void:
	var now := _now_secs()
	_recent_damage_times.append(now)
	_prune_damage_times(now)

func _took_consecutive_damage() -> bool:
	var now := _now_secs()
	_prune_damage_times(now)
	return _recent_damage_times.size() >= retaliate_combo_hits

func get_player() -> Node2D:
	return get_tree().get_first_node_in_group("Player") as Node2D
	
func _distance_to_player()->float:
	var p:= get_player()
	return abs(global_position.x-p.global_position.x)

func _update_facing() -> void:
	var p := get_player()
	if p == null:
		return

	var dx := p.global_position.x - global_position.x
	if abs(dx) <= 10:
		return

	change_direction(1 if dx > 0.0 else -1)
	
func _detect_player()->void:
	# Player detection is now handled by cutscene
	pass
			
func _update_level_bounds_from_markers() -> void:
	if bound_point_a == null or bound_point_b == null:
		level_bounds = Rect2()
		return

	var a := bound_point_a.global_position
	var b := bound_point_b.global_position

	var min_x = min(a.x, b.x)
	var max_x = max(a.x, b.x)
	var min_y = min(a.y, b.y)
	var max_y = max(a.y, b.y)

	level_bounds = Rect2(
		min_x,
		min_y,
		max_x - min_x,
		max_y - min_y
	)

func _init_jump_markers() -> void:
	jump_markers.clear()
	var markers = get_tree().get_nodes_in_group("jump_markers")
	for marker in markers:
		if marker is JumpMarker2D:
			jump_markers.append(marker)

func get_nearest_jump_marker() -> JumpMarker2D:
	if jump_markers.is_empty():
		return null

	var nearest = null
	var min_distance = INF

	for marker in jump_markers:
		if not marker.is_active:
			continue
		var distance = global_position.distance_to(marker.global_position)
		if distance < min_distance:
			min_distance = distance
			nearest = marker

	return nearest
	
func get_nearest_jump_marker_to_position(pos: Vector2) -> JumpMarker2D:
	if jump_markers.is_empty():
		return null

	var nearest: JumpMarker2D = null
	var min_distance := INF

	for marker in jump_markers:
		if not marker or not marker.is_active:
			continue

		var d := pos.distance_to(marker.global_position)
		if d < min_distance:
			min_distance = d
			nearest = marker

	return nearest

func get_best_jump_marker_to_player() -> JumpMarker2D:
	var player = get_player()
	if not player or jump_markers.is_empty():
		return null

	var best_marker = null
	var best_score = INF

	for marker in jump_markers:
		if not marker.is_active:
			continue

		var distance_to_player = marker.global_position.distance_to(player.global_position)
		var distance_to_boss = global_position.distance_to(marker.global_position)

		var score = distance_to_player + (distance_to_boss * 0.5) - (marker.jump_priority * 20.0)
		if not marker.is_safe_spot:
			score += 50.0

		if score < best_score:
			best_score = score
			best_marker = marker

	return best_marker

func should_defend() -> bool:
	if not can_defend or defend_cooldown_timer > 0:
		return false

	var player = get_player()
	if not player:
		return false

	var distance = _distance_to_player()
	if distance > defend_range:
		return false

	var player_dir = sign(player.global_position.x - global_position.x)
	var facing_dir = 1 if not animated_sprite_2d.flip_h else -1

	return player_dir == facing_dir

func update_defend_cooldown(delta: float) -> void:
	if defend_cooldown_timer > 0:
		defend_cooldown_timer -= delta
		if defend_cooldown_timer <= 0:
			can_defend = true

func start_defend_cooldown() -> void:
	can_defend = false
	defend_cooldown_timer = defend_cooldown

func update_attack_cooldown(delta: float) -> void:
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta
		if attack_cooldown_timer <= 0:
			can_attack = true

func start_attack_cooldown() -> void:
	can_attack = false
	attack_cooldown_timer = attack_prepare_time

func update_roll_cooldown(delta: float) -> void:
	if roll_cooldown_timer > 0:
		roll_cooldown_timer -= delta
		if roll_cooldown_timer <= 0:
			can_roll = true

func start_roll_cooldown() -> void:
	can_roll = false
	roll_cooldown_timer = roll_cooldown

func update_state_transition_cooldown(delta: float) -> void:
	if state_transition_cooldown > 0:
		state_transition_cooldown -= delta

func clamp_x_to_room(x: float) -> float:
	var lb: Rect2 = level_bounds
	if lb.size.x == 0.0:
		return x
	return clamp(x, lb.position.x, lb.position.x + lb.size.x)

func _keep_inside_room_and_avoid_fall() -> void:
	var lb: Rect2 = level_bounds
	if lb.size.x == 0.0:
		return

	var pos := global_position
	var left := lb.position.x
	var right := lb.position.x + lb.size.x

	var out_left := pos.x < left
	var out_right := pos.x > right

	if out_left or out_right:
		pos.x = clamp(pos.x, left, right)
		global_position = pos

		if is_on_floor() and fsm and fsm.current_state != fsm.states.roll:
			fsm.change_state(fsm.states.roll)
		return

	var dir_x = sign(velocity.x)
	if dir_x != 0:
		var ahead_x = pos.x + dir_x * 32.0
		if ahead_x <= left + 8.0 or ahead_x >= right - 8.0:
			if is_on_floor() and fsm and fsm.current_state != fsm.states.roll:
				fsm.change_state(fsm.states.roll)

func _start_phase2_transition() -> void:
	if _phase2_transition_running:
		return

	_phase2_transition_running = true

	_original_time_scale = Engine.time_scale

	if camera and camera.has_method("camera_shake"):
		camera.camera_shake(0.35, 20)

	flash_hurt(0.6, 2, Color(1, 1, 1, 1))

	Engine.time_scale = 0.15

	var tw := create_tween()
	tw.tween_interval(0.6)
	tw.tween_callback(Callable(self, "_finish_phase2_transition"))

func _finish_phase2_transition() -> void:
	Engine.time_scale = 1.0

	phase_2_talk.play()

	in_phase2 = true
	_phase2_transition_running = false

	emit_signal("into_phase2")

	phase_1.stop()
	phase_2_intro.play()

	# Show and animate phase 2 aura
	_show_phase2_aura()

func _show_phase2_aura() -> void:
	if not phase_2_aura:
		return

	phase_2_aura.visible = true
	_start_aura_animation()

func _hide_phase2_aura() -> void:
	if not phase_2_aura:
		return

	phase_2_aura.visible = false
	if _aura_tw and is_instance_valid(_aura_tw):
		_aura_tw.kill()
		_aura_tw = null

func _start_aura_animation() -> void:
	if not phase_2_aura:
		return

	if _aura_tw and is_instance_valid(_aura_tw):
		_aura_tw.kill()

	_aura_tw = create_tween().set_loops().set_parallel()

	# Pulse the energy
	_aura_tw.tween_method(_set_aura_energy, 0.8, 1.5, 1.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_aura_tw.tween_method(_set_aura_energy, 1.5, 0.8, 1.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE).set_delay(1.5)

	# Pulse the scale slightly
	var base_scale = phase_2_aura.scale
	_aura_tw.tween_property(phase_2_aura, "scale", base_scale * 1.2, 1.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_aura_tw.tween_property(phase_2_aura, "scale", base_scale, 1.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE).set_delay(1.5)

	# Pulse the color hue slightly for shimmering effect
	_aura_tw.tween_method(_set_aura_color_hue, 0.55, 0.6, 2.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_aura_tw.tween_method(_set_aura_color_hue, 0.6, 0.55, 2.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE).set_delay(2.0)

func _set_aura_energy(energy: float) -> void:
	if phase_2_aura:
		phase_2_aura.energy = energy

func _set_aura_color_hue(hue: float) -> void:
	if phase_2_aura:
		var color = phase_2_aura.color
		# Keep saturation and value, just change hue
		color.h = hue
		phase_2_aura.color = color
		
func _get_boss_platform_controller() -> Node:
	var stage = GameManager.current_stage
	if stage == null:
		return null

	if stage.has_node("World/BossPlatformController"):
		return stage.get_node("World/BossPlatformController")
	return null

func _check_player_attack_input() -> void:
	if not seen_player or _phase2_transition_running or fsm.current_state == fsm.states.roll or fsm.current_state == fsm.states.defend or fsm.current_state == fsm.states.atk_1 or fsm.current_state == fsm.states.atk_2 or fsm.current_state == fsm.states.atk_3 or fsm.current_state == fsm.states.atk_super or fsm.current_state == fsm.states.atk_air:
		return

	if Input.is_action_just_pressed("attack"):
		var player = get_player()
		if not player:
			return

		var distance_to_player = _distance_to_player()

		if distance_to_player <= attack_range:
			var should_use_defend = false
			var should_use_roll = false

			if can_defend and defend_cooldown_timer <= 0:
				var player_dir = sign(player.global_position.x - global_position.x)
				var facing_dir = 1 if not animated_sprite_2d.flip_h else -1

				if player_dir == facing_dir and distance_to_player <= defend_range:
					should_use_defend = true

			if not should_use_defend and can_roll and roll_cooldown_timer <= 0:
				should_use_roll = true

			if should_use_defend:
				start_defend_cooldown()
				fsm.change_state(fsm.states.defend)
			elif should_use_roll:
				start_roll_cooldown()
				fsm.change_state(fsm.states.roll)
				
func _on_phase_2_intro_finished() -> void:
	if in_phase2 and phase_2 and not phase_2.playing:
		phase_2.play()
	
func get_marker_at_pos(pos: Vector2) -> JumpMarker2D:
	if jump_markers.is_empty():
		return null

	var best: JumpMarker2D = null
	var best_score := INF

	for m in jump_markers:
		if m == null or not m.is_active:
			continue

		var half := m.platform_size * 0.5
		var dx = abs(pos.x - m.global_position.x)
		var dy = abs(pos.y - m.global_position.y)

		if dx <= half.x and dy <= half.y + 64.0:
			var score = dx + dy * 2.0
			if score < best_score:
				best_score = score
				best = m

	return best

func _boss_marker() -> JumpMarker2D:
	return get_marker_at_pos(global_position)

func _marker_for_pos(pos: Vector2) -> JumpMarker2D:
	var best: JumpMarker2D = null
	var best_score := INF

	for m in jump_markers:
		var jm := m as JumpMarker2D
		if jm == null or not jm.is_active:
			continue

		var half = jm.platform_size * 0.5
		var dx = abs(pos.x - jm.global_position.x)
		var dy = pos.y - jm.global_position.y  # has sign

		var x_tol = max(half.x, 16.0) + 10.0  # MARKER_X_PAD

		var base_y = max(half.y, 10.0)
		var y_up = min(base_y + 10.0, 70.0)  # MARKER_Y_UP_PAD, MARKER_Y_CAP
		var y_down = min(base_y + 40.0, 70.0)  # MARKER_Y_DOWN_PAD, MARKER_Y_CAP

		if dx > x_tol:
			continue
		if dy < -y_up:
			continue
		if dy > y_down:
			continue

		var score = dx + abs(dy) * 2.0
		if score < best_score:
			best_score = score
			best = jm

	return best
