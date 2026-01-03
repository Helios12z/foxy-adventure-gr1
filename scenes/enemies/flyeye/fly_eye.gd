extends EnemyCharacter

## Flying Eye enemy with vertical platform tracking AI
## Can fly up/down to reach player's platform level
## Uses Area2D for omnidirectional player detection
## Returns to original platform when player is lost

@export var minion_health: int = 80
@export var flight_speed: float = 60.0
@export var vertical_speed: float = 80.0
@export var vertical_detection_threshold: float = 20.0  # Y distance to consider same level
@export var detection_range: float = 250.0  # Radius for player detection
@export var home_position_threshold: float = 10.0  # Distance to consider "at home"
@export var patrol_range: float = 200.0  # Maximum distance from home to patrol

@onready var attack_scope_ray_cast = $Direction/AttackScopeRayCast2D
@onready var hurt_area = $Direction/HurtArea2D
@onready var animated_sprite_2d: AnimatedSprite2D = $Direction/AnimatedSprite2D

# Detection Area2D
@onready var detection_area: Area2D = $Direction/DetectionArea2D
@onready var detection_collision: CollisionShape2D = $Direction/DetectionArea2D/CollisionShape2D

var player: Player = null
var player_in_range: bool = false
var home_position: Vector2 = Vector2.ZERO  # Original spawn position


func _ready() -> void:
	max_health = minion_health
	super._ready()

	# Store home position before FSM starts
	home_position = global_position

	fsm = FSM.new(self, $States, $States/Walk)
	set_hit_collision(false)
	hurt_area.hurt.connect(_on_hurt_area_2d_hurt)

	# Set up detection area
	_setup_detection_area()


func _setup_detection_area() -> void:
	if detection_area:
		# Create a circle collision shape for omnidirectional detection
		var circle_shape = CircleShape2D.new()
		circle_shape.radius = detection_range

		if detection_collision:
			detection_collision.shape = circle_shape

		# Connect signals
		detection_area.body_entered.connect(_on_player_entered_detection)
		detection_area.body_exited.connect(_on_player_exited_detection)


func _on_player_entered_detection(body: Node2D) -> void:
	if body is Player:
		player = body
		player_in_range = true


func _on_player_exited_detection(body: Node2D) -> void:
	if body is Player and body == player:
		player = null
		player_in_range = false


func can_detect_player() -> bool:
	return player_in_range and player != null and is_instance_valid(player)


func is_in_attack_scope() -> bool:
	if attack_scope_ray_cast.is_colliding():
		return true
	return false


## Check if player is on a different vertical level
## Returns positive if player is above, negative if below, 0 if same level
func get_player_vertical_difference() -> float:
	if not player or not is_instance_valid(player):
		return 0.0

	var y_diff = player.global_position.y - global_position.y

	# Return 0 if within threshold (considered same level)
	if abs(y_diff) < vertical_detection_threshold:
		return 0.0

	return y_diff


## Check if there's a wall ahead
func is_wall_ahead() -> bool:
	return is_touch_wall()


## Check if currently at home position
func is_at_home() -> bool:
	var y_diff = abs(global_position.y - home_position.y)
	var x_diff = abs(global_position.x - home_position.x)
	return y_diff < home_position_threshold and x_diff < home_position_threshold


## Check if outside patrol range
## Returns true if FlyEye is too far from home position
func is_outside_patrol_range() -> bool:
	var distance = global_position.distance_to(home_position)
	return distance > patrol_range


## Check if should turn around based on patrol range
## Returns true if at patrol limit and moving away from home
func should_turn_for_patrol() -> bool:
	if not is_outside_patrol_range():
		return false

	# Calculate direction from home to current position
	var from_home = global_position.x - home_position.x

	# If moving away from home, turn around
	if from_home > 0 and direction > 0:
		return true  # Moving right, away from home
	if from_home < 0 and direction < 0:
		return true  # Moving left, away from home

	return false
