extends BaseCharacter

@export var max_health_boss: float = 600.0

@export var spike_damage: int = 70
@export var attack_speed: float = 50.0          
@export var attack_damage_boss: int = 50        
@export var bomb_move_speed: float = 50.0      
@export var stun_time: float = 2.0  

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

func _ready() -> void:
	# Boss đứng yên, không di chuyển
	movement_speed = 0.0
	velocity = Vector2.ZERO

	max_health = max_health_boss
	health = max_health

	super._ready()

	if hit_area_2d:
		hit_area_2d.damage = spike_damage
		
	_init_missile_targets()

	fsm = FSM.new(self, $States, $States/Idle)

func _physics_process(delta: float) -> void:
	if fsm != null:
		fsm._update(delta)

	velocity = Vector2.ZERO

	_update_facing()

	super._physics_process(delta)

func _on_hurt_area_hurt(_dir: Vector2, damage: float) -> void:
	take_damage(damage)

func _get_player() -> Node2D:
	return get_tree().get_first_node_in_group("Player") as Node2D

func _update_facing() -> void:
	var p := _get_player()
	if p == null:
		return

	var dir_x := 1 if p.global_position.x < global_position.x else -1
	change_direction(dir_x)

func _init_missile_targets() -> void:
	_missile_targets.clear()

	if missile_targets_root == NodePath(""):
		push_warning("WarlordTurtle: missile_targets_root is empty.")
		return

	if not has_node(missile_targets_root):
		push_warning("WarlordTurtle: missile_targets_root not found: %s" % missile_targets_root)
		return

	var root = get_node(missile_targets_root)

	for name in missile_target_names:
		var path := NodePath(str(name))  # ÉP StringName -> String -> NodePath

		if root.has_node(path):
			var n := root.get_node(path)
			if n is Node2D:
				_missile_targets.append(n)
		else:
			push_warning("WarlordTurtle: missile target '%s' not found under %s" % [name, missile_targets_root])
