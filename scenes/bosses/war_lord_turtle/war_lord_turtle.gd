extends BaseCharacter

@export var spike_damage: int = 70
@export var attack_speed: float = 50.0       
@export var attack_damage_boss: int = 50     
@export var bomb_move_speed: float = 50.0 
@export var fatigue_seconds_after_skill2: float = 2.0

@export var bomb_scene: PackedScene
@export var missile_scene: PackedScene
#add the parent node of 4 attack points on the map here 
@export var missile_targets_root: NodePath
@export var missile_target_names: Array[StringName] = ["A", "B", "C", "D"]

@onready var atk_1_shoot_point_1: Marker2D = $Direction/Atk1ShootPoint1
@onready var atk_1_shoot_point_2: Marker2D = $Direction/Atk1ShootPoint2
@onready var atk_2_shoot_point_1: Marker2D = $Direction/Atk2ShootPoint1
@onready var atk_2_shoot_point_2: Marker2D = $Direction/Atk2ShootPoint2

func _ready() -> void:
	super._ready()
	velocity = Vector2.ZERO
	#Considering add check if missile targets root is not a nodepath, but not too necessary
	
func _physics_process(delta: float) -> void:
	super._physics_process(delta)

func do_skill1() -> Signal:
	if bomb_scene == null:
		return get_tree().create_timer(0.0).timeout
		
	_spawn_bomb(atk_1_shoot_point_1, Vector2.LEFT)
	_spawn_bomb(atk_1_shoot_point_2, Vector2.RIGHT)
	
	return get_tree().create_timer(0.35).timeout

func do_skill2() -> Signal:
	if missile_scene == null:
		return get_tree().create_timer(0.0).timeout

	var guns := [atk_2_shoot_point_1, atk_2_shoot_point_2]
	var gi := 0
	var fired := 0

	if missile_target_names.is_empty():
		return get_tree().create_timer(0.0).timeout

	for t in _missile_targets:
		var gun := guns[gi % guns.size()]
		_fire_missile(gun, t.global_position)
		gi += 1
		fired += 1
	return get_tree().create_timer(0.4).timeout

func fatigue_duration() -> float:
	return fatigue_seconds_after_skill2

func _get_player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D

func _update_facing() -> void:
	var p := _get_player()
	if p == null: 
		return
	change_direction(-1 if p.global_position.x < global_position.x else 1)

func _spawn_bomb(from_node: Node2D, dir_vec: Vector2) -> void:
	if from_node == null: return
	var b := bomb_scene.instantiate()
	b.global_position = from_node.global_position
	get_tree().current_scene.add_child(b)

	if b.has_method("set"):
		b.set("move_speed", bomb_move_speed)
		b.set("dir", dir_vec)
	if "linear_velocity" in b:
		b.linear_velocity = dir_vec * bomb_move_speed
	if b.has_method("set_direction"):
		b.set_direction(-1 if dir_vec.x < 0 else 1)

func _fire_missile(from_node: Node2D, target_pos: Vector2) -> void:
	var m := missile_scene.instantiate()
	m.global_position = (from_node.global_position if from_node else global_position)
	get_tree().current_scene.add_child(m)

	if m.has_method("set"):
		m.set("target", target_pos)
		m.set("speed", attack_speed)
		m.set("damage", attack_damage_boss)
	elif m.has_method("init"):
		m.init(target_pos, attack_speed, attack_damage_boss)
