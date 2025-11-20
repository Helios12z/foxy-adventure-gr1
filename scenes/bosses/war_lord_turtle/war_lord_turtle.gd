extends BaseCharacter

@export var max_health_boss: float = 600.0

@export var spike_damage: int = 70
@export var attack_speed: float = 200.0          
@export var attack_damage_boss: int = 50        
@export var bomb_move_speed: float = 200.0      
@export var stun_time: float = 2.25  

@export var bomb_scene: PackedScene
@export var missile_scene: PackedScene

@export var missile_targets_root: NodePath
@export var missile_target_names: Array[StringName] = ["A", "B", "C", "D"]

# điểm bắn bomb (skill 1)
@onready var atk_1_shoot_point_1: Marker2D = $Direction/Atk1ShootPoint1
@onready var atk_1_shoot_point_2: Marker2D = $Direction/Atk1ShootPoint2

# điểm bắn tên lửa (skill 2)
@onready var atk_2_shoot_point_1: Marker2D = $Direction/Atk2ShootPoint1
@onready var atk_2_shoot_point_2: Marker2D = $Direction/Atk2ShootPoint2

@onready var hit_area_2d: HitArea2D = $Direction/HitArea2D
@onready var animated_sprite_2d: AnimatedSprite2D = $Direction/AnimatedSprite2D

var _missile_targets: Array[Node2D] = []

var seen_player: bool = false 

func _ready() -> void:
	movement_speed = 0.0
	velocity = Vector2.ZERO

	max_health = max_health_boss
	health = max_health

	super._ready()

	if hit_area_2d:
		hit_area_2d.damage = spike_damage
		
	_init_missile_targets()
	_init_hurt_area()

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
	fsm.change_state(fsm.states.hurt)

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
	if _distance_to_player()<=500: seen_player = true 

func _init_missile_targets() -> void:
	_missile_targets.clear()

	if missile_targets_root == NodePath(""):
		return

	if not has_node(missile_targets_root):
		return

	var root = get_node(missile_targets_root)

	for name in missile_target_names:
		var path := NodePath(str(name)) 

		if root.has_node(path):
			var n := root.get_node(path)
			if n is Node2D:
				_missile_targets.append(n)
		else:
			print("missile targets not found")
