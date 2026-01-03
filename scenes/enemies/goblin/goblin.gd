extends EnemyCharacter

@export var minion_health: int = 100
@export var retreat_speed: float = 180.0
@export var goblin_detection_range: float = 400.0

@onready var detect_front = $Direction/DetectFrontRayCast2D
@onready var detect_back = $Direction/DetectBackRayCast2D
@onready var attack_scope_ray_cast = $Direction/AttackScopeRayCast2D
@onready var hurt_area = $Direction/HurtArea2D
@onready var animated_sprite_2d: AnimatedSprite2D = $Direction/AnimatedSprite2D

var nearby_goblins: Array[EnemyCharacter] = []
var nearest_goblin: EnemyCharacter = null

func _ready() -> void:
	max_health = minion_health
	super._ready()
	fsm = FSM.new(self, $States, $States/Walk)
	set_hit_collision(false)
	hurt_area.hurt.connect(_on_hurt_area_2d_hurt)
	# Add to goblin group for tracking
	add_to_group("Goblins")

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_update_nearby_goblins()

# Update the list of nearby goblins
func _update_nearby_goblins() -> void:
	nearby_goblins.clear()
	var goblins = get_tree().get_nodes_in_group("Goblins")
	for goblin in goblins:
		if goblin != self and is_instance_valid(goblin):
			var distance = global_position.distance_to(goblin.global_position)
			if distance <= goblin_detection_range:
				nearby_goblins.append(goblin)

	# Find nearest goblin
	nearest_goblin = null
	if nearby_goblins.size() > 0:
		nearest_goblin = nearby_goblins[0]
		for goblin in nearby_goblins:
			if global_position.distance_to(goblin.global_position) < global_position.distance_to(nearest_goblin.global_position):
				nearest_goblin = goblin

# Check if should retreat (health below 50%)
func should_retreat() -> bool:
	return health < max_health * 0.5

# Check if near any goblin
func is_near_goblin() -> bool:
	return nearby_goblins.size() > 0

# Get position to retreat to (nearest goblin's position)
func get_retreat_position() -> Vector2:
	if nearest_goblin != null and is_instance_valid(nearest_goblin):
		return nearest_goblin.global_position
	return global_position

func can_detect_player() -> bool:
	# Kiểm tra nếu ray phía trước hoặc phía sau chạm Player
	if detect_front.is_colliding():
		var obj = detect_front.get_collider()
		return true

	if detect_back.is_colliding():
		var obj = detect_back.get_collider()
		turn_around()
		_check_changed_direction()
		return true

	return false

# check player in attack scope
func is_in_attack_scope() -> bool:
	if attack_scope_ray_cast.is_colliding():
		return true
	return false
