extends EnemyCharacter
class_name CeilingSpider

## Ceiling Spider - drops down from ceiling to attack player
## No gravity, uses raycast to detect player below, returns to origin after attack

@export var drop_speed: float = 200.0  # Tốc độ rơi xuống
@export var return_speed: float = 150.0  # Tốc độ leo lên
@export var attack_cooldown: float = 2.0  # Cooldown giữa các lần attack
@export var detection_range: float = 300.0  # Độ dài raycast detect player
@export var max_drop_distance: float = 200  # Khoảng cách tối đa spider rơi xuống

var origin_position: Vector2  # Vị trí ban đầu
var is_attacking: bool = false
var is_returning: bool = false
var can_attack: bool = true
var cooldown_timer: float = 0.0

# Silk line
var silk_line: Line2D = null
var silk_line_start_local: Vector2 = Vector2.ZERO  # Vị trí đầu sợi tơ (local)

# Raycast for player detection
var detect_raycast: RayCast2D = null

func _ready() -> void:
	# Disable gravity
	gravity = 0.0
	
	# Save origin position
	origin_position = global_position
	
	# Setup raycast for player detection
	_setup_detection_raycast()
	
	# Setup silk line
	_setup_silk_line()
	
	# Initialize FSM - must be done before super._ready()
	fsm = FSM.new(self, $States, $States/Idle)
	
	super._ready()

func _setup_detection_raycast() -> void:
	detect_raycast = RayCast2D.new()
	detect_raycast.name = "DetectPlayerRayCast"
	detect_raycast.target_position = Vector2(0, detection_range)  # Raycast xuống dưới
	detect_raycast.collision_mask = 2  # Layer 2 = player
	detect_raycast.enabled = true
	add_child(detect_raycast)

func _setup_silk_line() -> void:
	silk_line = Line2D.new()
	silk_line.name = "SilkLine_" + str(get_instance_id())
	silk_line.width = 1
	silk_line.default_color = Color(1, 1, 1, 0.8)  # White
	silk_line.z_index = 100  # Rất cao để chắc chắn hiện
	silk_line.visible = false
	silk_line.top_level = true  # Không bị ảnh hưởng bởi parent transform
	
	# Thêm trực tiếp vào spider trước, set top_level sẽ vẽ ở world space
	add_child(silk_line)
	print("[CeilingSpider] Silk line created with top_level=true")

func _physics_process(delta: float) -> void:
	# Update cooldown
	if not can_attack:
		cooldown_timer -= delta
		if cooldown_timer <= 0:
			can_attack = true
	
	# Check for player detection
	if can_attack and not is_attacking and not is_returning:
		_check_player_detection()
	
	# Update silk line
	_update_silk_line()
	
	# Don't call super to avoid gravity - update FSM manually
	if fsm:
		fsm._update(delta)
	_check_changed_animation()
	_check_changed_direction()

func _check_player_detection() -> void:
	if detect_raycast and detect_raycast.is_colliding():
		var collider = detect_raycast.get_collider()
		if collider is Player:
			_start_attack()

func _start_attack() -> void:
	is_attacking = true
	can_attack = false
	
	# Lưu vị trí đầu sợi tơ (tại vị trí hiện tại = origin)
	silk_line_start_local = Vector2.ZERO  # Vị trí local của spider lúc này
	
	# Show silk line
	silk_line.visible = true
	print("[CeilingSpider] Attack started! Silk line visible: ", silk_line.visible, " | Origin: ", origin_position, " | Global: ", global_position)
	
	# Change to attack state
	if fsm and fsm.states.has("attack"):
		fsm.change_state(fsm.states.attack)

func _start_return() -> void:
	is_attacking = false
	is_returning = true
	
	# Change to return state (or idle if no return state)
	if fsm and fsm.states.has("return"):
		fsm.change_state(fsm.states.return)

func _on_return_complete() -> void:
	is_returning = false
	cooldown_timer = attack_cooldown
	
	# Hide silk line
	silk_line.visible = false
	
	# Back to idle
	if fsm and fsm.states.has("idle"):
		fsm.change_state(fsm.states.idle)

func _update_silk_line() -> void:
	if silk_line and silk_line.visible:
		# Draw line from origin to current position (using global coords)
		silk_line.clear_points()
		silk_line.add_point(origin_position + Vector2(0, -9))  # Điểm đầu = offset lên trên
		silk_line.add_point(global_position + Vector2(0, -12))  # Điểm cuối = vị trí hiện tại của spider

func move_down(delta: float) -> bool:
	"""Move down during attack. Returns true if should stop (hit something or max distance)."""
	velocity.y = drop_speed
	move_and_slide()
	
	# Check if hit floor or max drop distance
	if is_on_floor() or global_position.y >= origin_position.y + max_drop_distance:
		velocity.y = 0
		return true
	return false

func move_up(delta: float) -> bool:
	"""Move up to return to origin. Returns true when reached origin."""
	var dir_to_origin = origin_position - global_position
	
	if dir_to_origin.length() <= 5.0:
		global_position = origin_position
		velocity = Vector2.ZERO
		return true
	
	velocity.y = -return_speed
	move_and_slide()
	return false

func get_origin_position() -> Vector2:
	return origin_position
