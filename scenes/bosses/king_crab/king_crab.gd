extends BaseCharacter

@export var king_crab_max_health: float = 500
@export var spike_damage: int = 50
@export var approach_speed: float = 50.0
@export var search_speed: float = 50.0
@export var king_crab_jump_speed: float = 320.0
@export var king_crab_gravity: float = 700.0
@export var attack_speed: float = 50.0
@export var king_crab_attack_damage: int = 50
@export var roll_speed_mult: float = 5.5
@export var roll_brake: float = 5000

@export var attack1_range: float = 350
@export var attack2_range: float = 1000
@export var roll_max_time: float = 3.5

@export var bullet_scene: PackedScene
@export var minion_scene: PackedScene

@export var teleport_proximity_seconds: float = 4.0     
@export var teleport_proximity_distance: float = 200.0 
@export var player_path: NodePath   
@export var teleport_damage_window_seconds: float = 5.0     
@export var teleport_combo_hits: int = 3            

@export var phase2_threshold_ratio: float = 0.7     
@export var atk3_cast_time: float = 1.5
@export var atk3_windup_time: float = 1.0
@export var atk3_hover_time: float = 0.6
@export var atk3_fly_height: float = 150.0         
@export var atk3_rise_speed: float = 600.0
@export var atk3_rise_accel: float = 2200.0    
@export var atk3_rise_decel_dist: float = 80.0  
@export var atk3_fall_speed: float = 1200.0
@export var atk3_dash_speed: float = 1600.0 
@export var chain_after_basic_prob: float = 0.5    
@export var atk3_strafe_speed: float = 900.0

@export var level_bounds: Rect2 = Rect2(-2000, -1200, 4000, 3000)
@export var teleport_clearance_margin: float = 0.5
@export var minion_clearance_margin: float = 0.5

var _recent_damage_times: PackedFloat32Array = []           
var _proximity_time: float = 0.0

# avoid wall/fall
var front_ray_cast: RayCast2D
var back_ray_cast: RayCast2D
var down_ray_cast: RayCast2D

# detect player
var detect_front_ray_cast: RayCast2D
var detect_back_ray_cast: RayCast2D

var found_player: Player = null
var _last_visible: bool = false
var detect_player_enable: bool = true

var _player_fallback: Node2D = null
var _player_search_cooldown: float = 0.0

var next_attack_is_claw: bool = true
var claw_busy = false
var claw_returned = false
var current_bullet: Node = null

var last_seen_player_x: float = 0.0
var has_last_seen: bool = false
var queued_bullet_dir_x: float = 1.0

var _flash_tw: Tween
var queued_roll_dir_x: float = 1.0

var in_phase2: bool = false
var _chain_after_basic: bool = false
var _atk3_drop_target := Vector2.ZERO
var _saved_gravity: float = 0.0
var _atk3_liftoff_x: float = 0.0
var _feet_offset_y: float = 0.0

@onready var hit_area_2d: HitArea2D = $Direction/HitArea2D
@onready var shoot_point: Marker2D = $Direction/ShootPoint
@onready var attack_1_effect: AnimatedSprite2D = $Direction/Attack1Effect
@onready var attack_2_effect: AnimatedSprite2D = $Direction/Attack2Effect
@onready var animated_sprite_2d: AnimatedSprite2D = $Direction/AnimatedSprite2D
@onready var teleport_effect: AnimatedSprite2D = $Direction/TeleportEffect
@onready var attack_3_cast_effect: AnimatedSprite2D = $Direction/Attack3CastEffect
@onready var attack_3_windup_effect: AnimatedSprite2D = $Direction/Attack3WindupEffect
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var attack_3_hover_effect: AnimatedSprite2D = $Direction/Attack3HoverEffect

func _ready() -> void:
	_init_ray_casts()
	_init_hurt_area()
	_disable_attack_effect()
	_disable_teleport_effect()
	_feet_offset_y = _compute_feet_offset_y()

	movement_speed = approach_speed
	max_health=king_crab_max_health
	gravity = king_crab_gravity
	jump_speed = king_crab_jump_speed
	attack_damage = king_crab_attack_damage
	direction=-1
	_next_direction=-1
	
	super._ready()
	fsm = FSM.new(self, $States, $States/Idle)
	
func _disable_attack_effect() -> void:
	attack_1_effect.visible = false
	attack_1_effect.stop()
	attack_1_effect.speed_scale = 1.0
	
	attack_2_effect.visible = false
	attack_2_effect.stop()
	attack_2_effect.speed_scale = 1.0
	
	attack_3_cast_effect.visible = false
	attack_3_cast_effect.stop()
	attack_3_cast_effect.speed_scale = 1.0
	
	attack_3_windup_effect.visible = false 
	attack_3_windup_effect.stop()
	attack_3_windup_effect.speed_scale = 1.0
	
	attack_3_hover_effect.visible = false 
	attack_3_hover_effect.stop()
	attack_3_hover_effect.speed_scale = 1.0
	
func play_attack_effect(type: int, duration: float) -> void:
	if type==1: 
		attack_1_effect.visible = true
		attack_1_effect.play("default")
		attack_1_effect.frame = 0

		var frames := attack_1_effect.sprite_frames.get_frame_count("default")
		var fps = max(attack_1_effect.sprite_frames.get_animation_speed("default"), 0.001)
		var base_duration = frames / fps                   
		attack_1_effect.speed_scale = base_duration / duration
	
	if type==2:
		attack_2_effect.visible = true
		attack_2_effect.play("default")
		attack_2_effect.frame = 0
		
		var frames := attack_2_effect.sprite_frames.get_frame_count("default")
		var fps = max(attack_2_effect.sprite_frames.get_animation_speed("default"), 0.001)
		var base_duration = frames / fps                   
		attack_2_effect.speed_scale = base_duration / duration
		
	if type==3:
		attack_3_cast_effect.visible = true 
		attack_3_cast_effect.play("default")
		attack_3_cast_effect.frame = 0 
		
		var frames := attack_3_cast_effect.sprite_frames.get_frame_count("default")
		var fps = max(attack_3_cast_effect.sprite_frames.get_animation_speed("default"), 0.001)
		var base_duration = frames / fps                   
		attack_3_cast_effect.speed_scale = base_duration / duration
		
	if type==4:
		attack_3_windup_effect.visible = true 
		attack_3_windup_effect.play("default")
		attack_3_windup_effect.frame = 0 
		
		var frames := attack_3_windup_effect.sprite_frames.get_frame_count("default")
		var fps = max(attack_3_windup_effect.sprite_frames.get_animation_speed("default"), 0.001)
		var base_duration = frames / fps                   
		attack_3_windup_effect.speed_scale = base_duration / duration
		
	if type==5:
		attack_3_hover_effect.visible = true 
		attack_3_hover_effect.play("default")
		attack_3_hover_effect.frame = 0 
		
		var frames := attack_3_hover_effect.sprite_frames.get_frame_count("default")
		var fps = max(attack_3_hover_effect.sprite_frames.get_animation_speed("default"), 0.001)
		var base_duration = frames / fps                   
		attack_3_hover_effect.speed_scale = base_duration / duration
		
func play_teleport_effect(duration: float)->void:
	teleport_effect.visible = true 
	teleport_effect.play("default")
	teleport_effect.frame = 0
	
	var frames := teleport_effect.sprite_frames.get_frame_count("default")
	var fps = max(teleport_effect.sprite_frames.get_animation_speed("default"), 0.001)
	var base_duration = frames / fps                   
	teleport_effect.speed_scale = base_duration / duration
	
func _disable_teleport_effect()->void:
	teleport_effect.visible = false
	teleport_effect.stop()
	teleport_effect.frame = 0
	teleport_effect.speed_scale = 1.0
	
func _physics_process(delta: float) -> void:
	if fsm != null:
		fsm._update(delta)
	_update_movement(delta)
	_check_changed_animation()
	check_changed_direction()
	check_player_visibility()
	_tick_proximity_teleport(delta)

func _init_ray_casts() -> void:
	if has_node("Direction/FrontRayCast2D"):
		front_ray_cast = $Direction/FrontRayCast2D
		front_ray_cast.enabled = true
		front_ray_cast.exclude_parent = true
	if has_node("Direction/DownRayCast2D"):
		down_ray_cast = $Direction/DownRayCast2D
		down_ray_cast.enabled = true
		down_ray_cast.exclude_parent = true

	if has_node("Direction/DetectFrontRayCast2D"):
		detect_front_ray_cast = $Direction/DetectFrontRayCast2D
		detect_front_ray_cast.enabled = true
		detect_front_ray_cast.exclude_parent = true
	if has_node("Direction/DetectBackRayCast2D"):
		detect_back_ray_cast = $Direction/DetectBackRayCast2D
		detect_back_ray_cast.enabled = true
		detect_back_ray_cast.exclude_parent = true
		
	if player_path!=NodePath("") and has_node(player_path):
		var n = get_node(player_path)
		if n is Node2D: _player_fallback = n  

func _init_hurt_area() -> void:
	if has_node("Direction/HurtArea2D"):
		var hurt_area = $Direction/HurtArea2D
		hurt_area.hurt.connect(_on_hurt_area_2d_hurt)
		
func _compute_feet_offset_y() -> float:
	if collision_shape_2d == null or collision_shape_2d.shape == null:
		return 0.0
	var rect: Rect2 = collision_shape_2d.shape.get_rect()      
	var bottom_local := Vector2(0, rect.position.y + rect.size.y)
	var bottom_global := collision_shape_2d.to_global(bottom_local)
	return bottom_global.y - global_position.y   

func is_touch_wall() -> bool:
	return front_ray_cast != null and front_ray_cast.is_colliding()

func is_can_fall() -> bool:
	return down_ray_cast != null and not down_ray_cast.is_colliding()

func _blocked_ahead() -> bool:
	return is_touch_wall() or is_can_fall()

func _ray_hits_player(ray: RayCast2D) -> Player:
	if ray == null:
		return null
	ray.force_raycast_update()
	if ray.is_colliding():
		var col := ray.get_collider()
		if col is Player:
			return col
	return null

func check_player_visibility() -> void:
	if not detect_player_enable:
		return

	var seen_player: Player = null
	if seen_player == null: seen_player = _ray_hits_player(detect_front_ray_cast)
	if seen_player == null: seen_player = _ray_hits_player(detect_back_ray_cast)

	if seen_player:
		found_player = seen_player
		_last_visible = true
		last_seen_player_x = seen_player.global_position.x
		has_last_seen = true
	else:
		_last_visible = false
		found_player = null

func _distance_to_player_x() -> float:
	if found_player == null: return INF
	return absf(found_player.global_position.x - global_position.x)

func can_attack1() -> bool:
	if found_player == null or claw_busy: return false
	return _distance_to_player_x() <= attack1_range

func can_attack2() -> bool:
	if found_player == null: return false
	return _distance_to_player_x() <= attack2_range

func control_move() -> bool:
	if found_player == null or _distance_to_player_x()>attack1_range or _distance_to_player_x()>attack2_range:
		if _blocked_ahead():
			change_direction(-direction)
		velocity.x = direction * search_speed
		return false 

	velocity.x = 0
	return true

func spawn_bullet_with_dir(dir_x: float) -> void:
	if bullet_scene == null or claw_busy: return
	var bullet = bullet_scene.instantiate()
	if not (bullet and bullet.has_method("launch")): return
	get_tree().current_scene.add_child(bullet)

	claw_busy = true
	claw_returned = false
	current_bullet = bullet

	var origin: Vector2
	var face: float 
	
	if is_instance_valid(shoot_point): origin=shoot_point.global_position 
	if dir_x!=0.0: face=sign(dir_x)
	else: dir_x=sign($"Direction".scale.x)
	if face == 0: face = 1
	var target := origin + Vector2(face * attack1_range, 0.0)

	if bullet.has_signal("returned"):
		bullet.connect("returned", Callable(self, "_on_bullet_returned"))
	if "spike_damage" in bullet:
		bullet.spike_damage = spike_damage

	bullet.launch(self, origin, target)

func _on_bullet_returned() -> void:
	claw_busy = false
	claw_returned = true
	current_bullet = null
	toggle_next_attack()

func _on_hurt_area_2d_hurt(_direction: Vector2, _damage: float) -> void:
	_take_damage_from_dir(_direction, _damage)

func _take_damage_from_dir(_damage_dir: Vector2, _damage: float) -> void:
	take_damage(_damage)
	_note_damage_hit()
	
	if not in_phase2 and health > 0 and health <= max_health * phase2_threshold_ratio:
		if fsm and fsm.current_state != fsm.states.dead and fsm.current_state != fsm.states.idle_atk and fsm.current_state != fsm.states.hurt_with_one_claw:
			in_phase2 = true
			_disable_attack_effect()
			fsm.change_state(fsm.states.atk3_cast)
		return
	
	if fsm.current_state==fsm.states.walk or fsm.current_state==fsm.states.idle or fsm.current_state==fsm.states.idle_stun or fsm.current_state==fsm.states.atk2_stop: 
		velocity.x = _damage_dir.x * 100
		fsm.change_state(fsm.states.hurt)
	elif fsm.current_state==fsm.states.idle_atk: 
		fsm.change_state(fsm.states.hurt_with_one_claw)
	else:
		flash_hurt(0.25, 3)
		if health <= 0: fsm.change_state(fsm.states.dead)
		
func flash_hurt(duration := 0.25, blinks := 3, color := Color(1, 0.2, 0.2, 1)) -> void:
	var mat := animated_sprite_2d.material as ShaderMaterial
	mat.set_shader_parameter("flash_color", color)
	mat.set_shader_parameter("flash_amount", 0.0)

	if is_instance_valid(_flash_tw):
		_flash_tw.kill()

	_flash_tw = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var step := duration / float(blinks * 2)
	for i in blinks:
		_flash_tw.tween_property(mat, "shader_parameter/flash_amount", 1.0, step)
		_flash_tw.tween_property(mat, "shader_parameter/flash_amount", 0.0, step)

func toggle_next_attack():
	next_attack_is_claw = not next_attack_is_claw

func check_changed_direction() -> void:
	if _next_direction != direction:
		direction = _next_direction
		if direction == 1:
			$Direction.scale.x = -1
		if direction == -1:
			$Direction.scale.x = 1
			
func reset_proximity_timer() -> void:
	_proximity_time = 0.0
	_recent_damage_times.clear()

func _is_player_continuously_close() -> bool:
	var near = false 
	if is_instance_valid(_player_fallback):
		var dx := absf(global_position.x - _player_fallback.global_position.x)
		near = dx <= teleport_proximity_distance
	var combo = _took_consecutive_damage()
	return near or combo

func _tick_proximity_teleport(delta: float) -> void:
	var s = fsm.current_state
	
	if s==fsm.states.atk1_windup or s==fsm.states.atk2_windup:
		return 
	
	elif s == fsm.states.teleport or s == fsm.states.dead \
	or s == fsm.states.atk3_cast or s == fsm.states.atk3_windup or s == fsm.states.atk3_fly_and_hit:
		_proximity_time = 0.0
		return

	if _is_player_continuously_close():
		_proximity_time += delta

	if _proximity_time >= teleport_proximity_seconds:
		_proximity_time = 0.0
		if s != fsm.states.hurt and s != fsm.states.atk2_roll and s != fsm.states.dead and s != fsm.states.idle_atk and s != fsm.states.hurt_with_one_claw and s != fsm.states.atk1_windup and s != fsm.states.atk2_windup:
			_disable_attack_effect()
			fsm.change_state(fsm.states.teleport)
			
func _ground_at(xy: Vector2, max_drop: float = 1000.0) -> Vector2:
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(xy, xy + Vector2(0, max_drop))
	query.exclude = [self]
	var hit := space_state.intersect_ray(query)
	if hit.has("position"):
		return Vector2(xy.x, hit.position.y)
	return xy

func spawn_minions() -> void:
	if minion_scene == null:
		return

	var offsets := [-160.0, -80.0, 80.0, 160.0]

	var parent_node: Node = null
	if get_tree().current_scene != null:
		parent_node = get_tree().current_scene
	else:
		parent_node = get_parent()

	for off in offsets:
		var dir_hint := 1
		if off < 0.0:
			dir_hint = -1

		var target_x = global_position.x + off
		target_x = clampf(target_x, level_bounds.position.x, level_bounds.position.x + level_bounds.size.x)

		var safe_pos := _find_safe_ground_near_x(
			target_x,
			global_position.y - 300.0,
			[0.0, 16.0, 32.0, 48.0, 64.0, 96.0],
			dir_hint
		)

		var m := minion_scene.instantiate()
		parent_node.add_child(m)

		var m_shape: Shape2D = null
		if m.has_node("CollisionShape2D"):
			var cs := m.get_node("CollisionShape2D") as CollisionShape2D
			if cs != null and cs.shape != null:
				m_shape = cs.shape
		if m_shape == null:
			var proxy := RectangleShape2D.new()
			proxy.size = Vector2(16, 20)
			m_shape = proxy

		var adjusted := safe_pos
		var ok := _is_free_at(adjusted, m_shape, minion_clearance_margin)
		if not ok:
			var fixed := false
			for dx in [8.0, -8.0, 16.0, -16.0, 24.0, -24.0]:
				var p := _clamp_to_level(adjusted + Vector2(dx, 0))
				if _is_free_at(p, m_shape, minion_clearance_margin):
					adjusted = p
					ok = true
					fixed = true
					break
			if not fixed or not ok:
				for dy in [-4.0, -8.0, -12.0]:
					var p2 := _clamp_to_level(adjusted + Vector2(0, dy))
					if _is_free_at(p2, m_shape, minion_clearance_margin):
						adjusted = p2
						ok = true
						break

		if m is Node2D:
			m.global_position = adjusted

		var dir := 1
		if off < 0.0:
			dir = -1

		if "direction" in m:
			m.direction = dir
		elif m.has_node("Direction"):
			var dnode := m.get_node("Direction")
			if dnode is Node2D:
				if dir == 1:
					dnode.scale.x = 1
				else:
					dnode.scale.x = -1

		if "play_spawn_intro" in m:
			var intro_total := 0.6
			var intro_times := 6
			var intro_color := Color8(255, 200, 64, 255)
			m.play_spawn_intro(intro_total, intro_times, intro_color)
			
func _now_secs() -> float:
	return Time.get_ticks_msec() / 1000.0

func _prune_damage_times(now_secs: float) -> void:
	while _recent_damage_times.size() > 0 and now_secs - _recent_damage_times[0] > teleport_damage_window_seconds:
		_recent_damage_times.remove_at(0)

func _note_damage_hit() -> void:
	var now := _now_secs()
	_recent_damage_times.append(now)
	_prune_damage_times(now)

func _took_consecutive_damage() -> bool:
	var now := _now_secs()
	_prune_damage_times(now)
	return _recent_damage_times.size() >= teleport_combo_hits
	
func _lock_drop_target_at_player() -> void:
	if _player_fallback != null:
		var px = _player_fallback.global_position.x
		var gy = _ground_at(Vector2(px, global_position.y - 200.0)).y
		_atk3_drop_target = Vector2(px, gy - _feet_offset_y)
	else:
		var gy = _ground_at(global_position).y
		_atk3_drop_target = Vector2(global_position.x, gy - _feet_offset_y)

func _begin_fly_mode() -> void:
	_saved_gravity = gravity
	gravity = 0.0
	velocity = Vector2.ZERO

func _end_fly_mode() -> void:
	gravity = _saved_gravity
	
func disable_collision_while_teleporting()->void:
	$Direction/HurtArea2D/CollisionShape2D.disabled=true 
	$Direction/HitArea2D/CollisionShape2D.disabled=true 
	
func enable_collision_after_teleporting()->void:
	$Direction/HurtArea2D/CollisionShape2D.disabled=false
	$Direction/HitArea2D/CollisionShape2D.disabled=false
	
func _snap_to_ground() -> void:
	var from := global_position
	var to   := from + Vector2(0, 32)  
	var space := get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(from, to)
	q.exclude = [self]
	var hit := space.intersect_ray(q)
	if hit and hit.has("position"):
		global_position.y = hit.position.y - _feet_offset_y
	
func _clamp_to_level(p: Vector2) -> Vector2:
	var px := clampf(p.x, level_bounds.position.x, level_bounds.position.x + level_bounds.size.x)
	var py := clampf(p.y, level_bounds.position.y, level_bounds.position.y + level_bounds.size.y)
	return Vector2(px, py)

func _safe_snap_ground(x: float, probe_top_y: float, max_drop: float = 1000.0) -> Vector2:
	var from := Vector2(x, probe_top_y)
	var gy := _ground_at(from, max_drop).y
	return _clamp_to_level(Vector2(x, gy - _feet_offset_y))

func _is_free_at(pos: Vector2, shape: Shape2D, margin: float = 0.0) -> bool:
	var space := get_world_2d().direct_space_state
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = Transform2D(0.0, pos)
	params.margin = margin
	params.exclude = [self]
	var results := space.intersect_shape(params, 1)
	return results.is_empty()

func _is_safe_ledge(pos: Vector2, dir: int, forward: float = 24.0, max_drop: float = 48.0) -> bool:
	var here := _ground_at(Vector2(pos.x, pos.y - 200.0)).y
	var ahead := _ground_at(Vector2(pos.x + dir * forward, pos.y - 200.0)).y
	return abs(here - ahead) <= max_drop

func _find_safe_ground_near_x(target_x: float, probe_top_y: float, try_radii := [0.0, 24.0, 48.0, 72.0, 96.0], dir_hint: int = 1) -> Vector2:
	var shape := collision_shape_2d.shape
	for r in try_radii:
		for sgn in [1, -1]:
			var x = target_x + sgn * r
			x = clampf(x, level_bounds.position.x, level_bounds.position.x + level_bounds.size.x)
			var pos := _safe_snap_ground(x, probe_top_y)
			if _is_free_at(pos, shape, 0.5) and _is_safe_ledge(pos, dir_hint):
				return pos
	return _clamp_to_level(global_position)

func _pick_safe_teleport_target(desired_x: float, probe_top_y: float) -> Vector2:
	# Ưu tiên ngay desired_x, rồi nới sang hai bên theo bán kính tăng dần
	var radii := [0.0, 32.0, 64.0, 96.0, 128.0, 160.0]
	var dir_hint := 1
	if found_player != null:
		if (found_player.global_position.x - global_position.x) < 0.0:
			dir_hint = -1
	elif has_last_seen:
		if (last_seen_player_x - global_position.x) < 0.0:
			dir_hint = -1

	var best := _find_safe_ground_near_x(desired_x, probe_top_y, radii, dir_hint)
	# Kiểm tra thêm free collision ở vị trí chọn được
	var shape := collision_shape_2d.shape
	var ok := _is_free_at(best, shape, teleport_clearance_margin)
	if ok:
		return best

	# Nếu vẫn dính, dịch nhỏ sang hai bên / nhích lên
	for dx in [8.0, -8.0, 16.0, -16.0, 24.0, -24.0]:
		var p := _clamp_to_level(best + Vector2(dx, 0))
		if _is_free_at(p, shape, teleport_clearance_margin):
			return p
	for dy in [-4.0, -8.0, -12.0]:
		var p2 := _clamp_to_level(best + Vector2(0, dy))
		if _is_free_at(p2, shape, teleport_clearance_margin):
			return p2

	return _clamp_to_level(best)
