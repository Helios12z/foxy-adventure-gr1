extends Node2D

# Susanoo spirit: follows player smoothly, mirrors attacks,
# and handles appear/disappear visual effects.

var player: Player = null
@export var follow_offset: Vector2 = Vector2(-60, -8)
@export var follow_smooth_speed: float = 8.0
@export var use_initial_position_as_offset: bool = true
@export var use_directional_offset: bool = true
@export var sync_facing_with_player: bool = true
@export var hit_enable_delay: float = 0.36
@export var bob_amplitude: float = 4.0
@export var bob_speed: float = 2.0
@export var lifetime: float = 7.0

var attacking: bool = false
var _attack_timer: Timer = null
var _hit_enable_timer: Timer = null
var _lifetime_timer: Timer = null
var _bob_phase: float = 0.0

var _sprite: AnimatedSprite2D = null
var _hit: HitArea2D = null

func _ready() -> void:
	player = (get_parent() as Player)
	# Nếu đặt vị trí sẵn trong Editor cho SusanooSpirit, dùng nó làm offset
	if use_initial_position_as_offset:
		follow_offset = position
		position = Vector2.ZERO
	_sprite = get_node_or_null("AnimatedSprite2D")
	_hit = get_node_or_null("HitArea2D")
	if _hit:
		# Ensure hit is disabled by default
		var shape := _hit.get_node_or_null("CollisionShape2D")
		if shape:
			shape.disabled = true

	if _sprite:
		# Start hidden until appear effect completes
		var c := _sprite.modulate
		c.a = 0.0
		_sprite.modulate = c
		_sprite.animation = "idle"
		_sprite.play()

	# Prepare attack timer
	_attack_timer = Timer.new()
	_attack_timer.one_shot = true
	_attack_timer.timeout.connect(_on_attack_timeout)
	add_child(_attack_timer)

	# Prepare hit enable timer (wind-up before collision becomes active)
	_hit_enable_timer = Timer.new()
	_hit_enable_timer.one_shot = true
	_hit_enable_timer.timeout.connect(_on_hit_enable_timeout)
	add_child(_hit_enable_timer)

	# Lifetime timer: tự kết thúc skill sau lifetime giây
	_lifetime_timer = Timer.new()
	_lifetime_timer.one_shot = true
	_lifetime_timer.wait_time = lifetime
	_lifetime_timer.timeout.connect(_on_lifetime_timeout)
	add_child(_lifetime_timer)
	_lifetime_timer.start()


	# Place immediately behind player at spawn
	if player:
		global_position = player.global_position + Vector2(follow_offset.x * get_player_dir(), follow_offset.y)

	# Kick off appear sequence
	play_appear_effect()

func _process(delta: float) -> void:
	if player == null:
		return
	var dir: float = get_player_dir()
	# Keep facing direction in sync
	if sync_facing_with_player:
		scale.x = dir
	# Smooth follow to a point behind the player
	var off_x: float = follow_offset.x * (dir if use_directional_offset else 1.0)
	# Bobbing mượt bằng sine (đong đưa rất nhỏ)
	_bob_phase += bob_speed * delta
	var bob: float = sin(_bob_phase) * bob_amplitude
	var target: Vector2 = player.global_position + Vector2(off_x, follow_offset.y + bob)
	# Exponential smoothing like Camera2D: frame-rate independent
	var alpha: float = 1.0 - exp(-follow_smooth_speed * delta)
	global_position.x = lerpf(global_position.x, target.x, alpha)
	global_position.y = lerpf(global_position.y, target.y, alpha)

	# Mirror player attack input
	if Input.is_action_just_pressed("attack"):
		start_attack()

func get_player_dir() -> float:
	if player == null:
		return 1.0
	return float(player.direction)

func start_attack() -> void:
	if attacking:
		return
	attacking = true
	if _sprite:
		_sprite.animation = "attack"
		_sprite.play()
	# Delay enabling hit collision for wind-up
	_hit_enable_timer.stop()
	_hit_enable_timer.wait_time = hit_enable_delay
	_hit_enable_timer.start()
	_attack_timer.wait_time = 0.55
	_attack_timer.start()

func _on_attack_timeout() -> void:
	attacking = false
	if _sprite:
		_sprite.animation = "idle"
		_sprite.play()
	if _hit:
		var shape := _hit.get_node_or_null("CollisionShape2D")
		if shape:
			shape.disabled = true

func _on_hit_enable_timeout() -> void:
	if _hit:
		var shape := _hit.get_node_or_null("CollisionShape2D")
		if shape:
			shape.disabled = false

func play_appear_effect() -> void:
	var tw := create_tween()
	tw.set_parallel(false)
	
	var tw2 := create_tween()
	tw2.set_parallel(true)
	tw2.tween_property(_sprite, "modulate:a", 0.58, 0.30).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func play_disappear_and_free() -> void:
	# Smooth blinking then disappear
	if _sprite == null:
		queue_free()
		return
	# Ensure hit disabled
	if _hit:
		var shape := _hit.get_node_or_null("CollisionShape2D")
		if shape:
			shape.disabled = true

	var tw := create_tween()
	tw.set_parallel(false)
	# Blink a few times by modulating alpha
	for i in range(4):
		tw.tween_property(_sprite, "modulate:a", 0.25, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(_sprite, "modulate:a", 0.75, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Fade out and free
	tw.tween_property(_sprite, "modulate:a", 0.0, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(Callable(self, "queue_free"))

func _on_lifetime_timeout() -> void:
	play_disappear_and_free()
