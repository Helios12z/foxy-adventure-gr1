extends RayCast2D

@export var growth_time: float = 0.1            
@export var cast_speed: float = 7000.0          
@export var max_length: float = 1400.0
@export var damage: int = 35

@export var is_casting := false: set = set_is_casting

@export var main_color: Color = Color(0.3, 0.9, 1.0, 1.0)
@export var inner_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var glow_color: Color = Color(0.2, 0.9, 1.0, 0.6)
@export var glow_width_multiplier: float = 1.8

@export var flicker_amount: float = 0.25       
@export var flicker_speed: float = 25.0        

@onready var hit_area_2d: HitArea2D = $HitArea2D
@onready var line_2d: Line2D = $Line2D
@onready var collision_shape_2d: CollisionShape2D = $HitArea2D/CollisionShape2D
@onready var capsule_shape: CapsuleShape2D = collision_shape_2d.shape as CapsuleShape2D

var glow_line_2d: Line2D = null
var impact_node: Node2D = null

var _base_width: float = 0.0
var _time: float = 0.0
var _tween: Tween = null

func _ready() -> void:
	hit_area_2d.damage = damage 

	hit_area_2d.monitorable = true
	hit_area_2d.monitoring = false

	if line_2d.points.size() < 2:
		line_2d.points = [Vector2.ZERO, Vector2.ZERO]

	_base_width = line_2d.width
	line_2d.width = 0.0
	line_2d.visible = false

	if capsule_shape:
		collision_shape_2d.rotation = PI / 2.0
		capsule_shape.radius = max(_base_width * 0.5, 2.0)
		capsule_shape.height = 0.0

	_setup_main_gradient()

	if has_node("GlowLine2D"):
		glow_line_2d = $GlowLine2D
		if glow_line_2d.points.size() < 2:
			glow_line_2d.points = [Vector2.ZERO, Vector2.ZERO]
		glow_line_2d.width = 0.0
		glow_line_2d.visible = false
		_setup_glow_gradient()

	if has_node("Impact"):
		impact_node = $Impact
		impact_node.visible = false

	set_physics_process(false)

func _physics_process(delta: float) -> void:
	if not is_casting:
		return

	_time += delta

	target_position.x = move_toward(
		target_position.x,
		max_length,
		cast_speed * delta
	)
	target_position.y = 0.0

	var laser_end_position := target_position

	force_raycast_update()
	if is_colliding():
		laser_end_position = to_local(get_collision_point())

	_update_beam_visual(laser_end_position, delta)

func set_is_casting(new_value: bool) -> void:
	if is_casting == new_value:
		return

	is_casting = new_value
	set_physics_process(is_casting)

	if not line_2d:
		return

	if not is_casting:
		target_position = Vector2.ZERO
		hit_area_2d.monitoring = false
		_start_disappear()
	else:
		target_position = Vector2.ZERO
		_time = 0.0
		hit_area_2d.monitoring = true
		_start_appear()

func _kill_tween() -> void:
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = null

func _start_appear() -> void:
	line_2d.visible = true
	line_2d.width = 0.0

	if glow_line_2d:
		glow_line_2d.visible = true
		glow_line_2d.width = 0.0

	_kill_tween()
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	_tween.tween_property(line_2d, "width", _base_width, growth_time).from(0.0)

	if glow_line_2d:
		_tween.parallel().tween_property(
			glow_line_2d,
			"width",
			_base_width * glow_width_multiplier,
			growth_time
		).from(0.0)

func _start_disappear() -> void:
	_kill_tween()

	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	_tween.tween_property(line_2d, "width", 0.0, growth_time).from_current()
	if glow_line_2d:
		_tween.parallel().tween_property(glow_line_2d, "width", 0.0, growth_time).from_current()

	_tween.tween_callback(_hide_beam)

func _hide_beam() -> void:
	line_2d.visible = false
	if glow_line_2d:
		glow_line_2d.visible = false

	if impact_node:
		impact_node.visible = false

	hit_area_2d.monitoring = false

func _update_beam_visual(end_pos: Vector2, delta: float) -> void:
	# ---- Visual beam ----
	line_2d.points[1] = end_pos
	if glow_line_2d:
		glow_line_2d.points[1] = end_pos

	var flicker := 1.0 + sin(_time * flicker_speed) * flicker_amount
	line_2d.width = _base_width * flicker
	if glow_line_2d:
		glow_line_2d.width = _base_width * glow_width_multiplier * (
			1.0 + flicker_amount * 0.5 * sin(_time * flicker_speed * 0.6)
		)

	# ---- Collider theo chiều dài beam ----
	if capsule_shape:
		var len := end_pos.length()

		hit_area_2d.position = end_pos * 0.5
		hit_area_2d.rotation = 0.0

		var min_radius = max(_base_width * 0.5, 4.0)
		capsule_shape.radius = min_radius

		var height = max(len - 2.0 * min_radius, 0.0)
		capsule_shape.height = height

	if impact_node:
		impact_node.global_position = to_global(end_pos)
		impact_node.visible = true

		if impact_node is AnimatedSprite2D:
			var anim := impact_node as AnimatedSprite2D
			if not anim.is_playing():
				anim.play()
		elif impact_node is GPUParticles2D:
			var ps := impact_node as GPUParticles2D
			ps.emitting = true

func _setup_main_gradient() -> void:
	var grad := Gradient.new()
	grad.colors = PackedColorArray([
		_color_with_alpha(main_color, 0.0),
		inner_color,
		main_color,
		_color_with_alpha(main_color, 0.0),
	])
	line_2d.gradient = grad

func _setup_glow_gradient() -> void:
	if glow_line_2d == null:
		return

	var grad := Gradient.new()
	grad.colors = PackedColorArray([
		_color_with_alpha(glow_color, 0.0),
		glow_color,
		glow_color,
		_color_with_alpha(glow_color, 0.0),
	])
	glow_line_2d.gradient = grad
	
func _color_with_alpha(c: Color, a: float) -> Color:
	return Color(c.r, c.g, c.b, a)
