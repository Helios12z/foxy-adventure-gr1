extends BaseCharacter

signal health_changed(current: float, max_health: float)
signal boss_died

@export var king_crab_max_health: float = 500
@export var spike_damage: int = 50
@export var speed: float = 50.0
@export var king_crab_gravity: float = 700.0
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

@export var teleport_clearance_margin: float = 0.5
@export var minion_clearance_margin: float = 0.5

@export var bound_point_a: Node2D
@export var bound_point_b: Node2D

@export var king_crab_shockwave_scene: PackedScene

var level_bounds: Rect2 

var _recent_damage_times: PackedFloat32Array = []           
var _proximity_time: float = 0.0

# avoid wall/fall
var front_ray_cast: RayCast2D
var down_ray_cast: RayCast2D

# detect player
var detect_front_ray_cast: RayCast2D
var detect_back_ray_cast: RayCast2D

var found_player: Player = null
var _last_visible: bool = false
var detect_player_enable: bool = true

var _player_fallback: Node2D = null

var last_seen_player_x: float = 0.0
var has_last_seen: bool = false

var _flash_tw: Tween

var in_phase2: bool = false
var _chain_after_basic: bool = false
var _atk3_drop_target := Vector2.ZERO
var _saved_gravity: float = 0.0
var _atk3_liftoff_x: float = 0.0
var _feet_offset_y: float = 0.0

var next_attack_is_claw: bool = true
var claw_busy = false
var claw_returned = false
var current_bullet: Node = null
var queued_bullet_dir_x: float = 1.0
var queued_roll_dir_x: float = 1.0

var hit_collision_default_pos: Vector2

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
@onready var camera: Camera2D = get_tree().get_first_node_in_group("Camera")
@onready var hurt_collision_shape_2d: CollisionShape2D = $Direction/HurtArea2D/CollisionShape2D
@onready var hit_collision_shape_2d: CollisionShape2D = $Direction/HitArea2D/CollisionShape2D
@onready var boss_direction: Node2D = $Direction

func _ready() -> void:
	_init_ray_casts()
	_init_hurt_area()
	_update_level_bounds_from_markers()
	_feet_offset_y = _compute_feet_offset_y()

	movement_speed = speed
	max_health=king_crab_max_health
	gravity = king_crab_gravity
	direction=-1
	_next_direction=-1
	
	super._ready()
	fsm = FSM.new(self, $States, $States/Idle)
	hit_area_2d.damage = spike_damage
	hit_collision_default_pos = hit_collision_shape_2d.position
	
	emit_signal("health_changed", health, max_health)
	
func _physics_process(delta: float) -> void:
	if fsm != null:
		fsm._update(delta)
	_update_movement(delta)
	_check_changed_animation()
	check_changed_direction()
	check_player_visibility()
	_tick_proximity_teleport(delta)
	
	if level_bounds.size != Vector2.ZERO:
		global_position = _clamp_to_level(global_position)

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

func _on_hurt_area_2d_hurt(_direction: Vector2, _damage: int) -> void:
	_take_damage(_damage)

func _take_damage(_damage: int) -> void:
	take_damage(_damage)
	emit_signal("health_changed", health, max_health)
	_note_damage_hit()
	
	if not in_phase2 and health > 0 and health <= max_health * phase2_threshold_ratio:
		if fsm and fsm.current_state != fsm.states.dead and fsm.current_state != fsm.states.idle_atk and fsm.current_state != fsm.states.hurt_with_one_claw:
			in_phase2 = true
			fsm.change_state(fsm.states.atk3_cast)
		return
	
	if fsm.current_state==fsm.states.walk or fsm.current_state==fsm.states.idle or fsm.current_state==fsm.states.idle_stun or fsm.current_state==fsm.states.atk2_stop: 
		fsm.change_state(fsm.states.hurt)
	elif fsm.current_state==fsm.states.idle_atk: 
		fsm.change_state(fsm.states.hurt_with_one_claw)
	else:
		flash_hurt(0.25, 3)
		if health <= 0: 
			emit_signal("boss_died")
			fsm.change_state(fsm.states.dead)
		
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
			fsm.change_state(fsm.states.teleport)
			
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
	
func _clamp_to_level(p: Vector2) -> Vector2:
	var px := clampf(p.x, level_bounds.position.x, level_bounds.position.x + level_bounds.size.x)
	var py := clampf(p.y, level_bounds.position.y, level_bounds.position.y + level_bounds.size.y)
	return Vector2(px, py)
	
func _update_level_bounds_from_markers() -> void:
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
