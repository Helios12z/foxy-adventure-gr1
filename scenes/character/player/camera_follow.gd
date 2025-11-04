extends Camera2D

@export var target_path: NodePath = ".."
@export var center_offset: Vector2 = Vector2(-1, -101)
@export var bottom_limit_y: float = INF
@export var overshoot_px: float = 24.0
@export var spring_k: float = 30.0
@export var damping_c: float = 12.0
@export var follow_smooth_speed: float = 8.0

var _target: Node2D = null
var _vel: Vector2 = Vector2.ZERO

func set_soft_bottom_limit(limit_y: float) -> void:
	bottom_limit_y = limit_y

func _ready() -> void:
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

	# Horizontal follow with exponential smoothing
	var alpha_x: float = 1.0 - exp(-follow_smooth_speed * delta)
	global_position.x = lerpf(global_position.x, desired.x, alpha_x)

	# Vertical: soft bottom limit with spring-damper
	var y: float = global_position.y
	if desired.y <= bottom_limit_y:
		# Normal follow region
		var alpha_y: float = 1.0 - exp(-follow_smooth_speed * delta)
		var new_y: float = lerpf(y, desired.y, alpha_y)
		# Reset vertical velocity when out of soft-limited region for stability
		_vel.y = 0.0
		y = new_y
	else:
		# Near/under ground: allow small overshoot then smoothly spring back
		var max_y: float = bottom_limit_y + overshoot_px
		# Clamp camera so it never shows too much underground
		y = min(y, max_y)
		# Spring toward bottom_limit_y around equilibrium at limit
		var displacement: float = y - bottom_limit_y
		var force: float = -spring_k * displacement - damping_c * _vel.y
		_vel.y += force * delta
		y += _vel.y * delta
		# Keep within overshoot band after integration
		y = clamp(y, -INF, max_y)

	global_position.y = y
