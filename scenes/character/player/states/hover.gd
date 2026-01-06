extends PlayerState

# Hover state: slow fall using dedicated hover animation with inflate/deflate and sway

var hover_fall_speed: float = 40.0
var hover_accel: float = 220.0
var sway_amp: float = 5.0
var sway_freq: float = 1.6
var sway_time: float = 0.0
var lead_tilt_deg: float = 8.0

# Inflate/deflate (visual scale) timings
var inflate_time: float = 0.20
var settle_time: float = 0.14
var deflate_time: float = 0.18
var inflate_target_scale: float = 1.35
var inflate_overshoot_scale: float = 1.49
var deflate_undershoot_scale: float = 0.65

var _tween: Tween = null
var _base_sprite_pos: Vector2 = Vector2.ZERO
var _exiting: bool = false
var _next_state = null
var _normal_body_collision: CollisionShape2D = null
var _hover_body_collision: CollisionShape2D = null
var _normal_hurt_shape: CollisionShape2D = null
var _hover_hurt_shape: CollisionShape2D = null
var _baseline_initialized: bool = false

# References to both sprites (always keep them synced)
var _normal_sprite: AnimatedSprite2D = null
var _hover_sprite: AnimatedSprite2D = null

# Separate baselines for each sprite (respect their original scales)
var _normal_base_scale: Vector2 = Vector2.ONE
var _hover_base_scale: Vector2 = Vector2.ONE

# Baselines and offsets to match sprite floating exactly
var _hover_body_base_pos: Vector2 = Vector2.ZERO
var _hover_body_base_scale: Vector2 = Vector2.ONE
var _hover_hurt_base_pos: Vector2 = Vector2.ZERO
var _hover_hurt_base_scale: Vector2 = Vector2.ONE
var _hover_body_offset_to_sprite: Vector2 = Vector2.ZERO
var _hover_hurt_offset_to_sprite: Vector2 = Vector2.ZERO

# Track last non-zero movement direction to prevent sway jitter
var _last_sway_direction: float = 1.0  # Default to right

func _enter() -> void:
	# Get references to both sprites
	_normal_sprite = obj.animated_sprite  # Current active sprite (Blade/Hat/Normal)
	_hover_sprite = obj.get_node_or_null("Direction/HoverAnimatedSprite2D")
	
	if not _hover_sprite:
		push_error("HoverAnimatedSprite2D not found!")
		return
	
	# Lấy baseline ONLY ONCE từ cả 2 sprite (lần đầu tiên vào hover)
	if not _baseline_initialized:
		_base_sprite_pos = _normal_sprite.position
		_normal_base_scale = _normal_sprite.scale  # Lưu scale gốc của Normal sprite
		_hover_base_scale = _hover_sprite.scale    # Lưu scale gốc của Hover sprite (0.1)
		_baseline_initialized = true
	
	# Đồng bộ POSITION và ROTATION (nhưng GIỮ NGUYÊN scale gốc của mỗi sprite)
	_hover_sprite.position = _normal_sprite.position
	_hover_sprite.rotation = _normal_sprite.rotation
	# Không sync scale ở đây - để mỗi sprite giữ scale gốc của nó
	
	# Toggle visibility
	_normal_sprite.visible = false
	_hover_sprite.visible = true
	
	# Play hover animation on HoverSprite
	if _hover_sprite.sprite_frames and _hover_sprite.sprite_frames.has_animation("hover"):
		_hover_sprite.play("hover")
	
	# Initialize sway direction to current facing direction
	_last_sway_direction = float(obj.direction)

	# Vô hiệu hóa gravity mặc định để tự kiểm soát tốc độ rơi mượt mà
	obj.set_ignore_gravity(true)

	sway_time = 0.0
	
	# Reset về baseline trước khi bắt đầu hover (mỗi sprite về scale gốc riêng)
	_hover_sprite.position = _base_sprite_pos
	_hover_sprite.rotation = 0.0
	_hover_sprite.scale = _hover_base_scale
	
	_normal_sprite.position = _base_sprite_pos
	_normal_sprite.rotation = 0.0
	_normal_sprite.scale = _normal_base_scale

	# Inflate with overshoot then settle to target scale (tween cả 2 sprite theo tỷ lệ riêng)
	if _tween:
		_tween.kill()
	
	_tween = create_tween()
	
	# Phase 1: Overshoot (both sprites scale up together)
	_tween.set_parallel(true)
	_tween.tween_property(
		_hover_sprite,
		"scale",
		_hover_base_scale * inflate_overshoot_scale,  # 0.1 * 1.49 = 0.149
		inflate_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(
		_normal_sprite,
		"scale",
		_normal_base_scale * inflate_overshoot_scale,  # 1.0 * 1.49 = 1.49
		inflate_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Transition: End parallel mode
	_tween.set_parallel(false)
	_tween.tween_interval(0)  # Dummy step to end phase 1
	
	# Phase 2: Settle (both sprites settle to target scale)
	_tween.set_parallel(true)
	_tween.tween_property(
		_hover_sprite,
		"scale",
		_hover_base_scale * inflate_target_scale,  # 0.1 * 1.35 = 0.135
		settle_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_tween.tween_property(
		_normal_sprite,
		"scale",
		_normal_base_scale * inflate_target_scale,  # 1.0 * 1.35 = 1.35
		settle_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	# Bật collider/hurt riêng cho hover, tắt collider/hurt mặc định
	_normal_body_collision = obj.get_node("CollisionShape2D") if obj.has_node("CollisionShape2D") else null
	_hover_body_collision = obj.get_node("HoverCollisionShape2D") if obj.has_node("HoverCollisionShape2D") else null
	_normal_hurt_shape = obj.get_node("Direction/HurtArea2D/CollisionShape2D") if obj.has_node("Direction/HurtArea2D/CollisionShape2D") else null
	_hover_hurt_shape = obj.get_node("Direction/HoverHurtArea2D/CollisionShape2D") if obj.has_node("Direction/HoverHurtArea2D/CollisionShape2D") else null

	if _normal_body_collision != null:
		_normal_body_collision.disabled = true
	if _hover_body_collision != null:
		_hover_body_collision.disabled = false
	if _normal_hurt_shape != null:
		_normal_hurt_shape.disabled = true
	if _hover_hurt_shape != null:
		_hover_hurt_shape.disabled = false

	# Capture baselines and offsets relative to sprite to mimic sway exactly
	var dir_node: Node2D = obj.get_node("Direction") if obj.has_node("Direction") else null
	if _hover_body_collision != null:
		_hover_body_base_pos = _hover_body_collision.position
		_hover_body_base_scale = _hover_body_collision.scale
		# Compute offset in Direction local space so it respects Direction's scale flip
		if dir_node != null:
			var body_pos_world := obj.to_global(_hover_body_base_pos)
			var body_pos_in_dir := dir_node.to_local(body_pos_world)
			_hover_body_offset_to_sprite = body_pos_in_dir - _base_sprite_pos
		else:
			# Fallback: no Direction node, use simple local difference
			_hover_body_offset_to_sprite = _hover_body_base_pos - _base_sprite_pos
	if _hover_hurt_shape != null:
		_hover_hurt_base_pos = _hover_hurt_shape.position
		_hover_hurt_base_scale = _hover_hurt_shape.scale
		_hover_hurt_offset_to_sprite = _hover_hurt_base_pos - _base_sprite_pos

	# Ensure initial sync so colliders match current sprite immediately
	_sync_hover_colliders_to_sprite()

	# Giảm nhẹ tốc độ ngang để cảm giác bay bổng
	obj.velocity.x = move_toward(obj.velocity.x, obj.velocity.x, 0)  # giữ nguyên hiện tại

	# Reset tốc độ rơi ngay lập tức nếu đang rơi quá nhanh (bỏ qua quán tính cũ)
	if obj.velocity.y > hover_fall_speed:
		obj.velocity.y = hover_fall_speed

func _update(delta: float) -> void:
	# Khi đang hover: KHÔNG cho dash/attack/climb
	# (không gọi control_dash/control_attack)

	# Tự động thoát hover khi chạm đất
	if obj.is_on_floor():
		_request_exit(fsm.states.idle)
		return

	# Rời hover: bắt đầu tween thu nhỏ và CHỜ hoàn tất rồi mới đổi state
	if Input.is_action_just_released("jump"):
		_request_exit(fsm.states.fall)
		return

	# Điều khiển di chuyển ngang trong Hover (không đổi state)
	var dir_input: float = Input.get_action_strength("right") - Input.get_action_strength("left")
	var is_moving: bool = abs(dir_input) > 0.1
	if is_moving:
		dir_input = sign(dir_input)
		obj.change_direction(dir_input)
		obj.velocity.x = dir_input * obj.movement_speed
	else:
		var current_deccel = obj.deccel if obj.is_on_floor() else obj.air_deccel
		obj.velocity.x = move_toward(obj.velocity.x, 0, current_deccel * delta)

	# Rơi chậm về tốc độ mục tiêu
	obj.velocity.y = move_toward(obj.velocity.y, hover_fall_speed, hover_accel * delta)

	# Sway nhẹ bằng position + tilt; và hiệu ứng thân trên kéo dẫn
	# Áp dụng cho CẢ HAI sprite để giữ đồng bộ
	if _hover_sprite != null and _normal_sprite != null:
		sway_time += delta
		var dir: float = sign(obj.velocity.x)
		
		# Update last sway direction only when actively moving
		# Prevents jitter when velocity.x crosses zero during deceleration
		if abs(obj.velocity.x) > 5.0:  # Threshold to ignore tiny velocities
			_last_sway_direction = dir
		
		var sway: float = sin(sway_time * TAU * sway_freq) * sway_amp
		# Lead based on speed: stronger tilt/offset when moving faster
		var lead: float = clamp(abs(obj.velocity.x) / 240.0, 0.0, 1.0)
		var target_rot: float = deg_to_rad(lead_tilt_deg) * dir * lead
		
		# Smooth rotation (áp dụng cho cả 2)
		var new_rot = lerp(_hover_sprite.rotation, target_rot, min(1.0, 6.0 * delta))
		_hover_sprite.rotation = new_rot
		_normal_sprite.rotation = new_rot

		# Position offset (áp dụng cho cả 2)
		var lead_push: float = 6.0 * lead
		
		# Use remembered sway direction instead of current velocity direction
		# This prevents sudden flip when velocity crosses zero
		var sway_dir = _last_sway_direction if abs(_last_sway_direction) > 0.1 else 1.0
		
		var new_pos_x = _base_sprite_pos.x + sway * sway_dir + dir * lead_push
		var new_pos_y = _base_sprite_pos.y - abs(sway) * 0.25 + (-lead * 2.0)
		
		_hover_sprite.position.x = new_pos_x
		_hover_sprite.position.y = new_pos_y
		_normal_sprite.position.x = new_pos_x
		_normal_sprite.position.y = new_pos_y

		# Sync hover colliders/hurt to match sprite transform and scale
		_sync_hover_colliders_to_sprite()

func _exit() -> void:
	# Khôi phục gravity mặc định
	obj.set_ignore_gravity(false)

	# Clear exit flags
	_exiting = false
	_next_state = null

	# Ngắt mọi tween đang chạy để tránh scale bị giữ khi chuyển state (ví dụ Hurt)
	if _tween:
		_tween.kill()
		_tween = null
	
	# Reset transform CẢ HAI sprite về baseline (mỗi sprite về scale gốc riêng)
	if _hover_sprite:
		_hover_sprite.position = _base_sprite_pos
		_hover_sprite.rotation = 0.0
		_hover_sprite.scale = _hover_base_scale
	if _normal_sprite:
		_normal_sprite.position = _base_sprite_pos
		_normal_sprite.rotation = 0.0
		_normal_sprite.scale = _normal_base_scale
	
	# Toggle visibility: ẩn Hover, hiện Normal
	if _hover_sprite:
		_hover_sprite.visible = false
	if _normal_sprite:
		_normal_sprite.visible = true

	# Khôi phục collider/hurt về mặc định
	_restore_default_colliders()


func _request_exit(to_state) -> void:
	if _exiting:
		return
	_exiting = true
	_next_state = to_state
	
	# Play shrinking/exit sound (same stretched sound)
	var dash_snd = AudioStreamPlayer.new()
	dash_snd.stream = load("res://asset/sounds/dash.mp3")
	dash_snd.bus = "SFX"
	dash_snd.volume_db = -5.0
	dash_snd.pitch_scale = 0.5 
	obj.add_child(dash_snd)
	dash_snd.play(0.2) 
	dash_snd.finished.connect(dash_snd.queue_free)

	# Thu nhỏ từ từ về undershoot rồi settle về baseline
	# Tween CẢ HAI sprite đồng thời
	if _hover_sprite and _normal_sprite:
		if _tween:
			_tween.kill()
		
		_tween = create_tween()
		
		# Phase 1: Undershoot
		_tween.set_parallel(true)
		_tween.tween_property(
			_hover_sprite,
			"scale",
			_hover_base_scale * deflate_undershoot_scale,  # 0.1 * 0.65 = 0.065
			deflate_time * 0.6
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_tween.tween_property(
			_normal_sprite,
			"scale",
			_normal_base_scale * deflate_undershoot_scale,  # 1.0 * 0.65 = 0.65
			deflate_time * 0.6
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		# Transition: End parallel mode
		_tween.set_parallel(false)
		_tween.tween_interval(0)  # Dummy step to end phase 1
		
		# Phase 2: Settle to baseline
		_tween.set_parallel(true)
		_tween.tween_property(
			_hover_sprite,
			"scale",
			_hover_base_scale,  # Về 0.1
			deflate_time
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		_tween.tween_property(
			_normal_sprite,
			"scale",
			_normal_base_scale,  # Về 1.0
			deflate_time
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		
		_tween.finished.connect(_on_exit_shrink_done)
	else:
		_on_exit_shrink_done()

func _on_exit_shrink_done() -> void:
	# Đảm bảo sprite và collider được reset hoàn toàn về trạng thái gốc
	if _hover_sprite:
		_hover_sprite.position = _base_sprite_pos
		_hover_sprite.rotation = 0.0
		_hover_sprite.scale = _hover_base_scale
	if _normal_sprite:
		_normal_sprite.position = _base_sprite_pos
		_normal_sprite.rotation = 0.0
		_normal_sprite.scale = _normal_base_scale
	
	# Khôi phục collider/hurt về mặc định
	_restore_default_colliders()
	
	if _next_state != null:
		change_state(_next_state)

func _sync_hover_colliders_to_sprite() -> void:
	# Compute scale factor relative to HOVER sprite's baseline
	# Use HoverSprite as reference since it's the visible one
	var scale_factor := Vector2(1, 1)
	if _hover_base_scale.x != 0 and _hover_sprite:
		scale_factor.x = _hover_sprite.scale.x / _hover_base_scale.x
	if _hover_base_scale.y != 0 and _hover_sprite:
		scale_factor.y = _hover_sprite.scale.y / _hover_base_scale.y

	var dir_node: Node2D = obj.get_node("Direction") if obj.has_node("Direction") else null
	var dir_pos: Vector2 = dir_node.position if dir_node != null else Vector2.ZERO

	# Body collision follows sprite smoothly
	if _hover_body_collision != null and _hover_sprite:
		_hover_body_collision.rotation = _hover_sprite.rotation
		# Rotate offset with sprite and transform through Direction to account for facing flip
		var rotated_offset := _hover_body_offset_to_sprite.rotated(_hover_sprite.rotation)
		var local_in_dir := _hover_sprite.position + rotated_offset
		var world_target := dir_node.to_global(local_in_dir)
		_hover_body_collision.position = obj.to_local(world_target)
		_hover_body_collision.scale = Vector2(
			_hover_body_base_scale.x * scale_factor.x,
			_hover_body_base_scale.y * scale_factor.y
		)

	# Hurt area follows sprite smoothly
	if _hover_hurt_shape != null and _hover_sprite:
		_hover_hurt_shape.rotation = _hover_sprite.rotation
		_hover_hurt_shape.position = _hover_sprite.position + _hover_hurt_offset_to_sprite
		_hover_hurt_shape.scale = Vector2(
			_hover_hurt_base_scale.x * scale_factor.x,
			_hover_hurt_base_scale.y * scale_factor.y
		)

func _restore_default_colliders() -> void:
	# Tắt collider/hurt hover, bật collider/hurt mặc định
	if _hover_body_collision != null:
		_hover_body_collision.rotation = 0.0
		_hover_body_collision.position = _hover_body_base_pos
		_hover_body_collision.scale = _hover_body_base_scale
		_hover_body_collision.disabled = true
	if _normal_body_collision != null:
		_normal_body_collision.disabled = false
	if _hover_hurt_shape != null:
		_hover_hurt_shape.rotation = 0.0
		_hover_hurt_shape.position = _hover_hurt_base_pos
		_hover_hurt_shape.scale = _hover_hurt_base_scale
		_hover_hurt_shape.disabled = true
	if _normal_hurt_shape != null:
		_normal_hurt_shape.disabled = false
