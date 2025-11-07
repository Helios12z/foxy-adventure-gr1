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

@export var stop_distance: float = 500
@export var attack1_range: float = 1000
@export var attack2_range: float = 800
@export var roll_max_time: float = 3.5

@export var bullet_scene: PackedScene

@export var teleport_proximity_seconds: float = 5.0     
@export var teleport_proximity_distance: float = 35.0 
@export var player_path: NodePath   

var _proximity_time: float = 0.0
var _proximity_enabled: bool = true

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

@onready var hit_area_2d: HitArea2D = $Direction/HitArea2D
@onready var shoot_point: Marker2D = $Direction/ShootPoint
@onready var attack_1_effect: AnimatedSprite2D = $Direction/Attack1Effect
@onready var attack_2_effect: AnimatedSprite2D = $Direction/Attack2Effect
@onready var animated_sprite_2d: AnimatedSprite2D = $Direction/AnimatedSprite2D
@onready var teleport_effect: AnimatedSprite2D = $Direction/TeleportEffect

func _ready() -> void:
	_init_ray_casts()
	_init_hurt_area()
	_disable_attack_effect()
	_disable_teleport_effect()

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
	attack_1_effect.frame = 0
	attack_1_effect.speed_scale = 1.0
	
	attack_2_effect.visible = false
	attack_2_effect.stop()
	attack_2_effect.frame = 0
	attack_2_effect.speed_scale = 1.0
	
func play_attack_windup_effect(type: int, duration: float) -> void:
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

func enable_check_player_in_sight() -> void:
	detect_player_enable = true

func disable_check_player_in_sight() -> void:
	if _last_visible:
		_last_visible = false
		found_player = null
	detect_player_enable = false

func _distance_to_player_x() -> float:
	if found_player == null: return INF
	return absf(found_player.global_position.x - global_position.x)

func can_attack1() -> bool:
	if found_player == null or claw_busy: return false
	return _distance_to_player_x() <= attack1_range

func can_attack2() -> bool:
	if found_player == null: return false
	return _distance_to_player_x() <= attack2_range

func _search_move() -> void:
	if _blocked_ahead():
		change_direction(-direction)
	velocity.x = direction * search_speed

func control_move() -> bool:
	if found_player == null:
		_search_move()
		return false 

	velocity.x = 0.0
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
	if fsm.current_state==fsm.states.walk or fsm.current_state==fsm.states.idle or fsm.current_state==fsm.states.idle_stun or fsm.current_state==fsm.states.atk2_stop or fsm.current_state==fsm.states.atk2_roll: 
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

func _is_player_continuously_close() -> bool:
	if is_instance_valid(_player_fallback):
		return global_position.distance_to(_player_fallback.global_position) <= teleport_proximity_distance
	return false

func _tick_proximity_teleport(delta: float) -> void:
	if not _proximity_enabled:
		return
		
	var s = fsm.current_state
	if s == fsm.states.teleport or s == fsm.states.dead:
		_proximity_time = 0.0
		return

	if _is_player_continuously_close():
		_proximity_time += delta
	else:
		if _proximity_time != 0.0:
			_proximity_time = 0.0

	if _proximity_time >= teleport_proximity_seconds:
		_proximity_time = 0.0
		if s != fsm.states.hurt and s != fsm.states.atk2_roll and s != fsm.states.dead and s != fsm.states.idle_atk and s != fsm.states.hurt_with_one_claw:
			_disable_attack_effect()
			fsm.change_state(fsm.states.teleport)
