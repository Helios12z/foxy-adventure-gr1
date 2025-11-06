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

@export var stop_distance: float = 180.0
@export var attack1_range: float = 1000
@export var attack2_range: float = 800
@export var roll_max_time: float = 3.5

@export var bullet_scene: PackedScene

# avoid wall/fall
var front_ray_cast: RayCast2D
var back_ray_cast: RayCast2D
var down_ray_cast: RayCast2D

# detect player
var detect_front_ray_cast: RayCast2D
var detect_back_ray_cast: RayCast2D
var detect_up_ray_cast: RayCast2D
var detect_down_ray_cast: RayCast2D

var found_player: Player = null
var _last_visible: bool = false
var detect_player_enable: bool = true

var next_attack_is_claw: bool = true
var claw_busy := false
var claw_returned := false
var current_bullet: Node = null

var last_seen_player_x: float = 0.0
var has_last_seen: bool = false
var queued_bullet_dir_x: float = 1.0

var knockback_direction: Vector2

@onready var hit_area_2d: HitArea2D = $Direction/HitArea2D
@onready var shoot_point: Marker2D = $Direction/ShootPoint
@onready var attack_effect: AnimatedSprite2D = $Direction/AttackEffect

func _ready() -> void:
	_init_ray_casts()
	_init_hurt_area()
	_disable_attack_effect()

	movement_speed = approach_speed
	max_health=king_crab_max_health
	gravity = king_crab_gravity
	jump_speed = king_crab_jump_speed
	attack_damage = king_crab_attack_damage
	direction=-1
	_next_direction=-1
	
	super._ready()
	fsm = FSM.new(self, $States, $States/Walk)
	
func _disable_attack_effect() -> void:
	attack_effect.visible = false
	attack_effect.stop()
	attack_effect.frame = 0
	attack_effect.speed_scale = 1.0
	
func play_attack_windup_effect(duration: float) -> void:
	attack_effect.visible = true
	attack_effect.play("default")
	attack_effect.frame = 0

	var frames := attack_effect.sprite_frames.get_frame_count("default")
	var fps = max(attack_effect.sprite_frames.get_animation_speed("default"), 0.001)
	var base_duration = frames / fps                   
	attack_effect.speed_scale = base_duration / duration
	
func _physics_process(delta: float) -> void:
	if fsm != null:
		fsm._update(delta)
	_update_movement(delta)
	_check_changed_animation()
	check_changed_direction()
	check_player_visibility()

func _init_ray_casts() -> void:
	if has_node("Direction/FrontRayCast2D"):
		front_ray_cast = $Direction/FrontRayCast2D
		front_ray_cast.enabled = true
		front_ray_cast.exclude_parent = true
	if has_node("Direction/BackRayCast2D"):
		back_ray_cast = $Direction/BackRayCast2D
		back_ray_cast.enabled = true
		back_ray_cast.exclude_parent = true
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
	if has_node("Direction/DetectUpRayCast2D"):
		detect_up_ray_cast = $Direction/DetectUpRayCast2D
		detect_up_ray_cast.enabled = true
		detect_up_ray_cast.exclude_parent = true
	if has_node("Direction/DetectDownRayCast2D"):
		detect_down_ray_cast = $Direction/DetectDownRayCast2D
		detect_down_ray_cast.enabled = true
		detect_down_ray_cast.exclude_parent = true

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
	if seen_player == null: seen_player = _ray_hits_player(detect_up_ray_cast)
	if seen_player == null: seen_player = _ray_hits_player(detect_down_ray_cast)

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

func update_chase_motion() -> bool:
	if found_player == null:
		return false

	var px := found_player.global_position.x
	var dx := px - global_position.x
	var dist := absf(dx)

	if dist > stop_distance:
		var dir_x: float
		if dx == 0.0:
			dir_x = direction
		else:
			dir_x = sign(dx)  

		velocity.x = dir_x * movement_speed

		if dir_x > 0.0 and direction != 1:
			change_direction(1)
		elif dir_x < 0.0 and direction != -1:
			change_direction(-1)

		return false
	else:
		velocity.x = 0.0
		return true

func _search_move() -> void:
	if _blocked_ahead():
		change_direction(-direction)
	velocity.x = direction * search_speed

func control_move() -> bool:
	if found_player == null:
		_search_move()

	var ready := update_chase_motion()

	return ready

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
	knockback_direction = _damage_dir.normalized()
	if fsm and fsm.current_state:
		fsm.current_state.take_damage(_damage_dir, _damage)

func toggle_next_attack():
	next_attack_is_claw = not next_attack_is_claw

func check_changed_direction() -> void:
	if _next_direction != direction:
		direction = _next_direction
		if direction == 1:
			$Direction.scale.x = -1
		if direction == -1:
			$Direction.scale.x = 1
