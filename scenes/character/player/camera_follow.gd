extends Camera2D

@export var target_path: NodePath = ".."
@export var center_offset: Vector2 = Vector2(-1, -101)
@export var bottom_limit_y: float = INF
@export var overshoot_px: float = 24.0
@export var spring_k: float = 30.0
@export var damping_c: float = 12.0
@export var follow_smooth_speed: float = 8.0

@export var default_shake_duration: float = 0.4
@export var default_shake_magnitude: float = 16.0

var _target: Node2D = null
var _vel: Vector2 = Vector2.ZERO

var _shake_time_left: float = 0.0
var _shake_duration: float = 0.0
var _shake_magnitude: float = 0.0
var _rng := RandomNumberGenerator.new()

func set_soft_bottom_limit(limit_y: float) -> void:
	bottom_limit_y = limit_y

func _ready() -> void:
	_rng.randomize()

	# Resolve target
	if target_path != NodePath(""):
		_target = get_node_or_null(target_path)
	if _target == null:
		_target = get_parent() as Node2D

	# Pull per-stage configured bottom limit if available
	if GameManager.current_stage != null and GameManager.current_stage.has_method("get_camera_bottom_limit_y"):
		bottom_limit_y = GameManager.current_stage.get_camera_bottom_limit_y()

func _process(delta: float) -> void:
	if _target == null:
		return

	var desired: Vector2 = _target.global_position + center_offset

	# Horizontal follow với smoothing exp
	var alpha_x: float = 1.0 - exp(-follow_smooth_speed * delta)
	var next_x := lerpf(global_position.x, desired.x, alpha_x)

	# Vertical: soft bottom limit với spring-damper
	var y: float = global_position.y
	if desired.y <= bottom_limit_y:
		# Normal follow region
		var alpha_y: float = 1.0 - exp(-follow_smooth_speed * delta)
		var new_y: float = lerpf(y, desired.y, alpha_y)
		# Reset vertical velocity khi ra khỏi vùng soft-limit
		_vel.y = 0.0
		y = new_y
	else:
		# Near/under ground: cho overshoot nhẹ rồi kéo bằng lò xo
		var max_y: float = bottom_limit_y + overshoot_px
		y = min(y, max_y)
		var displacement: float = y - bottom_limit_y
		var force: float = -spring_k * displacement - damping_c * _vel.y
		_vel.y += force * delta
		y += _vel.y * delta
		y = clamp(y, -INF, max_y)

	var final_pos := Vector2(next_x, y)

	# ----- APPLY CAMERA SHAKE (nếu còn thời gian) -----
	if _shake_time_left > 0.0:
		_shake_time_left -= delta
		var t = _shake_time_left / max(_shake_duration, 0.0001)
		# Giảm biên độ dần về 0
		var current_mag = _shake_magnitude * t
		var offset = Vector2(
			_rng.randf_range(-1.0, 1.0),
			_rng.randf_range(-1.0, 1.0)
		) * current_mag
		final_pos += offset
	else:
		_shake_time_left = 0.0

	global_position = final_pos
	
func camera_shake(duration: float = -1.0, magnitude: float = -1.0) -> void:
	if duration <= 0.0:
		duration = default_shake_duration
	if magnitude <= 0.0:
		magnitude = default_shake_magnitude

	_shake_duration = duration
	_shake_time_left = duration
	_shake_magnitude = magnitude
