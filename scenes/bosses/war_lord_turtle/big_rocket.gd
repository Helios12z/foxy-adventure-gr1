extends RigidBody2D

var speed: float        
var damage: int 
@export var arc_height: float = 150.0   
@export var explosion: PackedScene

var target: Vector2

var _p0: Vector2
var _p1: Vector2
var _p2: Vector2
var _t: float = 0.0
var _duration: float = 1.0
var _exploding := false

var _last_pos: Vector2
var _current_rot: float = 0.0

var _finished_arc: bool = false
var _fly_dir: Vector2 = Vector2.ZERO

@onready var animated_sprite_2d: AnimatedSprite2D = $Sprite2D
@onready var hit_area: Area2D = $HitArea2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var hit_collision_shape_2d: CollisionShape2D = $HitArea2D/CollisionShape2D

func init(p_target: Vector2, p_speed: float, p_damage: int) -> void:
	target = p_target
	speed = p_speed
	damage = p_damage

func _ready() -> void:
	gravity_scale = 0.0
	linear_velocity = Vector2.ZERO

	_p0 = global_position

	if target == Vector2.ZERO:
		target = _p0 + Vector2(0, 200)

	_p2 = target

	var horizontal_offset := absf(_p2.x - _p0.x)
	var vertical_dive_threshold := 80.0 

	if horizontal_offset < vertical_dive_threshold:
		_finished_arc = true
		_fly_dir = _p2 - _p0
		if _fly_dir.length() < 0.01:
			_fly_dir = Vector2.DOWN
		else:
			_fly_dir = _fly_dir.normalized()

		var target_rot = _fly_dir.angle() + PI / 2.0
		_current_rot = target_rot
		rotation = _current_rot
	else:
		var mid := (_p0 + _p2) * 0.5
		var peak_y = min(_p0.y, _p2.y) - arc_height
		_p1 = Vector2(mid.x, peak_y)

		var approx_len := _p0.distance_to(_p1) + _p1.distance_to(_p2)
		_duration = max(0.25, approx_len / max(speed, 1.0))

	_t = 0.0

	_last_pos = global_position
	_current_rot = 0.0

	if animated_sprite_2d:
		animated_sprite_2d.rotation = 0.0
	if collision_shape_2d:
		collision_shape_2d.rotation = 0.0
	if hit_collision_shape_2d:
		hit_collision_shape_2d.rotation = 0.0
	if hit_area:
		hit_area.damage = damage
		hit_area.rotation = 0.0
		if hit_area.has_signal("area_entered"):
			hit_area.area_entered.connect(_on_hit_area_entered)

	if has_signal("body_entered"):
		body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if _exploding:
		return

	if not _finished_arc:
		_t += delta / _duration
		var t = clamp(_t, 0.0, 1.0)
		var omt = 1.0 - t

		var pos = omt * omt * _p0 + 2.0 * omt * t * _p1 + t * t * _p2
		var dir = pos - _last_pos

		global_position = pos

		# Quay đầu theo hướng bay
		if dir.length() > 0.01:
			var target_rot = dir.angle() + PI / 2.0
			_current_rot = lerp_angle(_current_rot, target_rot, 0.2)
			rotation = _current_rot

		_last_pos = pos

		if t >= 1.0:
			_finished_arc = true
			if dir.length() > 0.01:
				_fly_dir = dir.normalized()
			else:
				_fly_dir = Vector2.DOWN
	else:
		if _fly_dir == Vector2.ZERO:
			_fly_dir = Vector2.DOWN

		var move := _fly_dir * speed * delta
		global_position += move

		var target_rot = _fly_dir.angle() + PI / 2.0
		_current_rot = lerp_angle(_current_rot, target_rot, 0.2)
		rotation = _current_rot


func _on_hit_area_entered(area: Area2D) -> void:
	if _exploding:
		return
	explode()

func _on_body_entered(body: Node) -> void:
	if _exploding:
		return
	explode()

func explode() -> void:
	if _exploding:
		return
	_exploding = true

	_spawn_explosion()
	queue_free()

func _spawn_explosion() -> void:
	if explosion == null:
		return

	var ex = explosion.instantiate()
	var parent := get_tree().current_scene if get_tree().current_scene != null else get_parent()
	parent.add_child(ex)
	ex.global_position = global_position
