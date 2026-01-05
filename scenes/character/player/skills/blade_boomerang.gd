extends Area2D
class_name BladeBoomerang

## Blade boomerang projectile - flies out and returns to player with arc trajectory

signal returned

@export var speed: float = 650.0
@export var max_range: float = 350.0
@export var damage: int = 20
@export var rotation_speed: float = 720.0
@export var return_stop_radius: float = 25.0
@export var arc_height: float = 150.0  # Độ cao của vòng cung khi quay về

enum State { GOING_OUT, RETURNING }
var current_state: State = State.GOING_OUT

var player: Node2D = null
var origin: Vector2
var direction: Vector2 = Vector2.RIGHT
var traveled: float = 0.0
var rotation_angle: float = 0.0

# Arc return variables
var arc_start_pos: Vector2  # Vị trí bắt đầu quay về
var arc_control_pos: Vector2  # Điểm điều khiển bezier (phía trên)
var arc_end_pos: Vector2  # Vị trí kết thúc (player)
var arc_t: float = 0.0  # Progress trên curve (0 -> 1)
var arc_duration: float = 0.0  # Thời gian để hoàn thành arc

# Sound
const WHOOSH_SOUND = preload("res://asset/sounds/boomerang_whoosh.mp3")
var throw_sound: AudioStreamPlayer2D = null
var return_sound: AudioStreamPlayer2D = null

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit_area: HitArea2D = $HitArea2D

func _ready() -> void:
	if hit_area:
		hit_area.damage = damage
		# Connect signal to detect when hitting enemy
		hit_area.hitted.connect(_on_hit_enemy)
	# Play spinning animation
	if sprite:
		sprite.play("spin")
	
	# Setup sound players
	_setup_sounds()

func _setup_sounds() -> void:
	# Throw sound - normal pitch, short
	throw_sound = AudioStreamPlayer2D.new()
	throw_sound.stream = WHOOSH_SOUND
	throw_sound.bus = "SFX"
	throw_sound.volume_db = -3.0
	throw_sound.pitch_scale = 1.0
	add_child(throw_sound)
	
	# Return sound - higher pitch for "coming back" feel
	return_sound = AudioStreamPlayer2D.new()
	return_sound.stream = WHOOSH_SOUND
	return_sound.bus = "SFX"
	return_sound.volume_db = -2.0
	return_sound.pitch_scale = 1.3  # Cao hơn khi quay về
	add_child(return_sound)

func _on_hit_enemy(_area: Area2D) -> void:
	# Khi chạm enemy, quay về player (nếu chưa đang quay về)
	if current_state == State.GOING_OUT:
		_start_return()

func launch(_player: Node2D, _direction: float) -> void:
	player = _player
	origin = player.global_position
	global_position = origin + Vector2(0, -15)  # Offset Y lên trên
	
	# Set direction based on player facing
	direction = Vector2.RIGHT if _direction > 0 else Vector2.LEFT
	
	# Play throw sound
	if throw_sound:
		throw_sound.play()
	
func _physics_process(delta: float) -> void:
	# Rotate blade
	rotation_angle += rotation_speed * delta
	rotation_degrees = rotation_angle
	
	match current_state:
		State.GOING_OUT:
			_process_going_out(delta)
		State.RETURNING:
			_process_returning_arc(delta)

func _process_going_out(delta: float) -> void:
	# Move outward
	global_position += direction * speed * delta
	traveled += speed * delta
	
	# Check if should return
	if traveled >= max_range or _hit_wall():
		_start_return()

func _process_returning_arc(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		queue_free()
		return
	
	# Update end position to follow player
	arc_end_pos = player.global_position + Vector2(0, -15)
	
	# Update control point (giữa start và end, nhưng cao hơn)
	var mid_x: float = (arc_start_pos.x + arc_end_pos.x) / 2.0
	arc_control_pos = Vector2(mid_x, min(arc_start_pos.y, arc_end_pos.y) - arc_height)
	
	# Progress along curve
	arc_t += delta * speed / _calculate_arc_length()
	arc_t = clamp(arc_t, 0.0, 1.0)
	
	# Calculate position on quadratic bezier curve
	global_position = _quadratic_bezier(arc_start_pos, arc_control_pos, arc_end_pos, arc_t)
	
	# Check if reached player
	if arc_t >= 1.0 or global_position.distance_to(arc_end_pos) <= return_stop_radius:
		_on_returned()

func _quadratic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
	# Quadratic Bezier: B(t) = (1-t)²P0 + 2(1-t)tP1 + t²P2
	var u: float = 1.0 - t
	return u * u * p0 + 2.0 * u * t * p1 + t * t * p2

func _calculate_arc_length() -> float:
	# Estimate arc length for consistent speed
	var direct_dist: float = arc_start_pos.distance_to(arc_end_pos)
	return direct_dist + arc_height  # Rough estimate

func _hit_wall() -> bool:
	# Raycast to check for walls
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + direction * 10,
		1  # Layer 1 = environment
	)
	query.exclude = [self]
	var result = space_state.intersect_ray(query)
	return result.size() > 0

func _start_return() -> void:
	current_state = State.RETURNING
	
	# Play return sound (higher pitch)
	if return_sound:
		return_sound.play()
	
	# Setup arc trajectory
	arc_start_pos = global_position
	arc_t = 0.0
	
	if player and is_instance_valid(player):
		arc_end_pos = player.global_position + Vector2(0, -15)
		# Control point - cao hơn cả start và end
		var mid_x: float = (arc_start_pos.x + arc_end_pos.x) / 2.0
		arc_control_pos = Vector2(mid_x, min(arc_start_pos.y, arc_end_pos.y) - arc_height)

func _on_returned() -> void:
	emit_signal("returned")
	queue_free()
