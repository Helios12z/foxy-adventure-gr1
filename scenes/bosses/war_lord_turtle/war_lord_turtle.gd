extends BaseCharacter

@export var max_health_boss: float = 600.0

@export var spike_damage: int = 70
@export var attack_speed: float = 200.0          
@export var attack_damage_boss: int = 50        
@export var bomb_move_speed: float = 200.0      
@export var stun_time: float = 2.25  

@export var bomb_scene: PackedScene
@export var missile_scene: PackedScene
@export var big_missile_scene: PackedScene

# điểm bắn bomb (skill 1)
@onready var atk_1_shoot_point_1: Marker2D = $Direction/Atk1ShootPoint1
@onready var atk_1_shoot_point_2: Marker2D = $Direction/Atk1ShootPoint2

# điểm bắn tên lửa (skill 2)
@onready var atk_2_shoot_point_1: Marker2D = $Direction/Atk2ShootPoint1
@onready var atk_2_shoot_point_2: Marker2D = $Direction/Atk2ShootPoint2

@onready var atk_3_shoot_point: Marker2D = $Direction/Atk3ShootPoint

@onready var hit_area_2d: HitArea2D = $Direction/HitArea2D
@onready var animated_sprite_2d: AnimatedSprite2D = $Direction/AnimatedSprite2D

@onready var target_lock_effect: AnimatedSprite2D = $Direction/TargetLockEffect

@export var phase2_threshold_ratio: float = 0.7

@export var bound_point_a: Node2D
@export var bound_point_b: Node2D

@export var retaliate_damage_window_seconds: float = 6.0 #6 seconds
@export var retaliate_combo_hits: int = 3  #3 hits

var _missile_targets: Array[Node2D] = []
var seen_player: bool = false 
var _flash_tw: Tween
var in_phase2: bool = false
var _recent_damage_times: PackedFloat32Array = []
var level_bounds: Rect2

func _ready() -> void:
	movement_speed = 0.0
	velocity = Vector2.ZERO

	max_health = max_health_boss
	health = max_health

	super._ready()

	if hit_area_2d:
		hit_area_2d.damage = spike_damage

	_init_hurt_area()
	_update_level_bounds_from_markers()

	fsm = FSM.new(self, $States, $States/Idle)

func _physics_process(delta: float) -> void:
	if fsm != null: fsm._update(delta)

	_update_facing()
	_detect_player()

	super._physics_process(delta)

func _init_hurt_area() -> void:
	if has_node("Direction/HurtArea2D"):
		var hurt_area = $Direction/HurtArea2D
		hurt_area.hurt.connect(_on_hurt_area_2d_hurt)

func _on_hurt_area_2d_hurt(_dir: Vector2, damage: float) -> void:
	take_damage(damage)
	_note_damage_hit()
	
	if fsm.current_state != fsm.states.idle:
		flash_hurt(0.25, 3)

	if health <= 0.0:
		if fsm and fsm.current_state != fsm.states.dead:
			fsm.change_state(fsm.states.dead)
		return

	if not in_phase2 and health <= max_health * phase2_threshold_ratio:
		in_phase2 = true
		if fsm and fsm.current_state != fsm.states.dead:
			fsm.change_state(fsm.states.atk_3_windup)
		return

	if _took_consecutive_damage():
		if not in_phase2 and fsm.current_state != fsm.states.atk_2 and fsm.current_state != fsm.states.dead:
			fsm.change_state(fsm.states.atk_2)
		_recent_damage_times.clear()
		return 

	if fsm.current_state == fsm.states.idle:
		fsm.change_state(fsm.states.hurt)

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

func _get_player() -> Node2D:
	return get_tree().get_first_node_in_group("Player") as Node2D
	
func _distance_to_player()->float:
	var p:= _get_player()
	return abs(global_position.x-p.global_position.x)

func _update_facing() -> void:
	var p := _get_player()
	if p == null:
		return

	var dir_x := 1 if p.global_position.x < global_position.x else -1
	change_direction(dir_x)
	
func _detect_player()->void:
	if seen_player: return
	if _distance_to_player()<=280: seen_player = true 
			
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
