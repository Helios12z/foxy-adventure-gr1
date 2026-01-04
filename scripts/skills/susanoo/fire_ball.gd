extends Path2D

signal appeared
signal vanished

@export var fade_in_duration: float = 0.225
@export var wait_before_fall: float = 1.0
@export var fall_duration: float = 0.18
@export var acc_trans: Tween.TransitionType = Tween.TRANS_EXPO
@export var acc_ease: Tween.EaseType = Tween.EASE_IN

# Physics-driven acceleration along path (robust vs tween timing)
@export var fall_speed_start: float = 0.5   # progress_ratio per second at start
@export var fall_accel: float = 2.2         # acceleration of progress per second^2
@export var fall_speed_max: float = 6.0     # clamp to avoid overshoot

# Bobbing (small smooth vertical oscillation with inertia)
@export var bob_amplitude: float = 5.0
@export var bob_speed: float = 9.0
@export var bob_damping: float = 0.12

# Afterimage trail (similar to player dash)
@export var ghost_interval: float = 0.06

# RayCast-based fire hole spawn control
@export var min_platform_gap: float = 8.0
var _last_hit_y: float = -99999.0
@export var hole_contact_reset_time: float = 0.038
var _hole_contact_countdown: float = 0.0

const SCALE_CHOICES: Array[float] = [0.9, 1.3, 1.6]

var _pf: PathFollow2D
var _body: AnimatableBody2D
var _sprite: AnimatedSprite2D
var _ray: RayCast2D

var _base_body_y: float = 0.0
var _base_sprite_y: float = 0.0
var _bob_phase: float = 0.0
var _bob_vel: float = 0.0
var _bob_pos: float = 0.0

var _falling: bool = false
var _elapsed: float = 0.0
var _last_ghost: float = 0.0
var _fall_speed: float = 0.0
var _active: bool = false
var _ray_was_colliding: bool = false

func _ready() -> void:
	_pf = get_node_or_null("PathFollow2D")
	_body = get_node_or_null("PathFollow2D/AnimatableBody2D")
	_sprite = get_node_or_null("PathFollow2D/AnimatableBody2D/AnimatedSprite2D")
	_ray = get_node_or_null("PathFollow2D/AnimatableBody2D/RayCast2D")
	if _sprite:
		var c := _sprite.modulate
		c.a = 0.0
		_sprite.modulate = c
	# Disable collisions on AnimatableBody2D so it never blocks Area2D detection or platforms
	if _body:
		_body.collision_layer = 0
		_body.collision_mask = 0
		_base_body_y = _body.position.y
	if _sprite:
		_base_sprite_y = _sprite.position.y
	# Randomize overall body scale among 3 options (affects sprite + hit area)
	var choice := SCALE_CHOICES[randi() % SCALE_CHOICES.size()]
	if _body:
		_body.scale = Vector2(choice, choice)
	_pf.progress_ratio = 0.0
	_bob_phase = randf() * TAU

	# Auto-destroy after 7 seconds
	var life_timer := get_tree().create_timer(5.0)
	life_timer.timeout.connect(queue_free)

	# Ensure both process loops are active
	set_physics_process(true)
	set_process(true)
	
	# Prepare impact sound (King Crab explosion style)
	var snd := AudioStreamPlayer2D.new()
	snd.name = "ImpactSound"
	snd.stream = load("res://asset/sounds/king_crab_sound/explosion.mp3")
	snd.bus = "SFX"
	snd.volume_db = -2.0 # Slightly lower volume for spammy fireballs
	# Add to PathFollow2D so it moves with the ball until impact
	if _pf:
		_pf.add_child(snd)
	else:
		add_child(snd)

func start(delay: float) -> void:
	# Staggered appearance per ball
	await get_tree().create_timer(max(delay, 0.0)).timeout
	# Fade in smoothly
	if _sprite:
		var tw := create_tween()
		tw.tween_property(_sprite, "modulate:a", 1.0, fade_in_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await tw.finished
		appeared.emit()
	# Kích hoạt bobbing ngay khi xuất hiện (phạm vi nhỏ, có quán tính)
	_active = true
	# Wait before falling
	await get_tree().create_timer(wait_before_fall).timeout
	# Start physics-driven fall; avoids cases where tween is interrupted
	_falling = true
	_fall_speed = fall_speed_start
	# Áp dụng shader warp giống dash khi rơi nhanh
	_apply_dash_shader(true)

func _physics_process(delta: float) -> void:
	if not _falling:
		return
	# Visuals handled in _process; physics here manages raycast + path progress

	# Detect platform below and spawn fire hole with countdown reset on continuous contact
	var colliding := false
	var hit_point := Vector2.ZERO
	var hit_normal := Vector2.ZERO
	if _ray:
		_ray.force_raycast_update()
		colliding = _ray.is_colliding()
		if colliding:
			hit_point = _ray.get_collision_point()
			hit_normal = _ray.get_collision_normal()
	# Fallback: ray thẳng xuống bắt mọi layer, chỉ nhận platform và mặt trên cùng
	if not colliding and _body:
		var space := get_world_2d().direct_space_state
		if space:
			var from: Vector2 = _body.global_position
			var to: Vector2 = from + Vector2(0, 24)
			var params := PhysicsRayQueryParameters2D.create(from, to)
			params.exclude = [_body]
			params.collision_mask = 0xFFFF
			var result := space.intersect_ray(params)
			if result.size() > 0:
				var collider: Node = result.get("collider") as Node
				if collider != null and _is_platform_node(collider):
					colliding = true
					if result.has("position"):
						hit_point = (result["position"] as Vector2)
					else:
						hit_point = from
					if result.has("normal"):
						hit_normal = (result["normal"] as Vector2)
					else:
						hit_normal = Vector2.UP
	if colliding:
		# Reset countdown every detection frame; spawn only when countdown has expired
		if _hole_contact_countdown <= 0.0:
			_spawn_firehole(hit_point)
			_last_hit_y = hit_point.y
		_hole_contact_countdown = hole_contact_reset_time
		_ray_was_colliding = true
	else:
		# Count down when not detecting surface; allows next hole after gap
		if _hole_contact_countdown > 0.0:
			_hole_contact_countdown = max(0.0, _hole_contact_countdown - delta)
		_ray_was_colliding = false

	# Progress along the path with increasing speed
	if _pf:
		_fall_speed = min(_fall_speed + fall_accel * delta, fall_speed_max)
		_pf.progress_ratio = min(1.0, _pf.progress_ratio + _fall_speed * delta)
		if _pf.progress_ratio >= 1.0:
			_falling = false
			# Tắt hiệu ứng shader khi kết thúc rơi
			_apply_dash_shader(false)

func _process(delta: float) -> void:
	# Bobbing mượt mà (cả khi vừa xuất hiện lẫn khi đang rơi)
	if not _active and not _falling:
		return
	_elapsed += delta
	# Smooth bobbing using a spring-like approach
	_bob_phase += bob_speed * delta
	var target := sin(_bob_phase) * bob_amplitude
	var accel := (target - _bob_pos) * bob_speed
	_bob_vel += accel * delta
	_bob_vel *= (1.0 - bob_damping)
	_bob_pos += _bob_vel
	if _sprite:
		_sprite.position.y = _base_sprite_y + _bob_pos
	# Afterimage trail
	if _falling and (_elapsed - _last_ghost >= ghost_interval):
		_spawn_afterimage()
		_last_ghost = _elapsed

func _apply_dash_shader(enable: bool) -> void:
	if _sprite == null:
		return
	if enable:
		var shader := load("res://scenes/character/player/shaders/dash_warp.gdshader")
		if shader == null:
			return
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("warp", 1.6)
		mat.set_shader_parameter("squash", 0.85)
		mat.set_shader_parameter("lean", 0.0)
		mat.set_shader_parameter("lean_cutoff", 0.58)
		mat.set_shader_parameter("dir", 1.0)
		_sprite.material = mat
	else:
		var mat2: Material = _sprite.material
		if mat2 is ShaderMaterial:
			(mat2 as ShaderMaterial).set_shader_parameter("warp", 0.0)
			(mat2 as ShaderMaterial).set_shader_parameter("squash", 0.0)
			(mat2 as ShaderMaterial).set_shader_parameter("lean", 0.0)

func _spawn_afterimage() -> void:
	if _body == null or _sprite == null:
		return
	var container := Node2D.new()
	# Add to the current scene so it stays in world space
	var root := get_tree().current_scene
	if root == null:
		return
	root.add_child(container)
	container.set_as_top_level(true)
	container.global_position = _body.global_position
	# Match visual scale closely to the sprite to avoid distortion
	container.scale = _sprite.scale * _body.scale
	# Ensure afterimage renders above environment/FX
	container.z_index = 100
	var ghost := AnimatedSprite2D.new()
	if _sprite.sprite_frames != null:
		ghost.sprite_frames = _sprite.sprite_frames
	ghost.animation = _sprite.animation
	ghost.frame = _sprite.frame
	ghost.stop()
	ghost.modulate = Color(1, 1, 1, 0.6)
	ghost.light_mask = 2
	# Keep it upright like source sprite; skip copying global rotation to avoid tilt glitches
	ghost.rotation = _sprite.rotation
	ghost.z_index = 100
	container.add_child(ghost)
	var tw := container.create_tween()
	tw.tween_property(ghost, "modulate:a", 0.0, 0.22)
	tw.tween_callback(Callable(container, "queue_free"))

func _spawn_firehole(pos: Vector2) -> void:
	var ps := load("res://scenes/skills/susanoo/fire_hole.tscn") as PackedScene
	if ps == null:
		return
	var hole := ps.instantiate() as Node2D
	var root := get_tree().current_scene
	if root:
		root.add_child(hole)
		hole.global_position = pos + Vector2(0, -2)
		
	# Play impact sound if available
	var snd = null
	if _pf:
		snd = _pf.get_node_or_null("ImpactSound")
	else:
		snd = get_node_or_null("ImpactSound")
		
	if snd and snd is AudioStreamPlayer2D:
		# Detach sound to play it fully even if ball vanishes
		var sound_root = snd.duplicate()
		if root:
			root.add_child(sound_root)
			sound_root.global_position = pos
			sound_root.play()
			# Auto-cleanup sound object
			sound_root.finished.connect(sound_root.queue_free)

func vanish() -> void:
	_falling = false
	_active = false
	_apply_dash_shader(false)
	vanished.emit()
	if _sprite:
		var tw := create_tween()
		tw.tween_property(_sprite, "modulate:a", 0.0, 0.12)
		tw.tween_callback(Callable(self, "queue_free"))
	else:
		queue_free()

func _is_platform_node(body: Node) -> bool:
	if body == null:
		return false
	if body.has_method("is_in_group") and body.is_in_group("platform"):
		return true
	var name_str := String(body.name).to_lower()
	return name_str.find("platform") != -1
