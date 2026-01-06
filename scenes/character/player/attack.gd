extends PlayerState

var direction_node: Node2D
var hurt_area: Area2D
var original_direction_offset := Vector2.ZERO
var original_hurt_offset := Vector2.ZERO
var forward_offset := 20
var elapsed_time: float = 0.0  # Track thời gian đã trôi qua
var giant_hit_enabled: bool = false  # Đánh dấu đã bật hit collision cho giant chưa

func _enter():
	# Get Direction node and HurtArea2D
	direction_node = obj.get_node("Direction")
	hurt_area = obj.get_node("Direction/HurtArea2D")

	# Play attack sound - giant or normal
	print("[Attack] is_giant_mode: ", obj.is_giant_mode)
	if obj.is_giant_mode:
		obj.giant_attack_sound.play()
	else:
		obj.attack_sound.play()
	
	# Reset tracking variables
	elapsed_time = 0.0
	giant_hit_enabled = false

	if obj.current_animation != "attack":
		obj.change_animation("attack")
	
	if obj.is_giant_mode:
		timer = 0.5
		obj.velocity.x = 0
	else:
		timer = 0.3
	
	if not obj.is_giant_mode:
		obj.set_hit_collision(true)

	# Save original offsets
	original_direction_offset = direction_node.position
	original_hurt_offset = hurt_area.position

	# Offset Direction node forward (moves sprite and hitbox)
	if obj.is_right():
		direction_node.position = Vector2(original_direction_offset.x + forward_offset, original_direction_offset.y)
		# Compensate hurt area backward to keep it in correct position
		hurt_area.position = Vector2(original_hurt_offset.x - forward_offset, original_hurt_offset.y)
	else:
		direction_node.position = Vector2(original_direction_offset.x - forward_offset, original_direction_offset.y)
		# Compensate hurt area backward (note: Direction.scale.x = -1 when facing left, so sign is inverted)
		hurt_area.position = Vector2(original_hurt_offset.x - forward_offset, original_hurt_offset.y)




func _update(delta: float):
	# Track elapsed time
	elapsed_time += delta
	
	# Bật hit collision cho giant mode sau 0.2s (delay để khớp animation)
	if obj.is_giant_mode and not giant_hit_enabled and elapsed_time > 0.2:
		obj.set_hit_collision(true)
		giant_hit_enabled = true
		
	if update_timer(delta):
		change_state(fsm.previous_state)


func _exit():
	obj.set_hit_collision(false)
	# Reset positions
	if direction_node:
		direction_node.position = original_direction_offset
	if hurt_area:
		hurt_area.position = original_hurt_offset
