extends PlayerState

var hurt_timer: float = 0.2          # Thời gian sau khi hurt trở lại idle
var knockback_force: Vector2 = Vector2(100, -200)  # Lực hất văng (X, Y)
var elapsed_time: float = 0.0

func _enter() -> void:
	obj.change_animation("hurt")
	#obj.can_control = false  # vô hiệu hóa input trong lúc hurt
	# Hướng hất văng dựa vào direction (ngược chiều đang nhìn)
	obj.set_detect_and_hurt_collsion(false)
	var dir = -obj.direction
	obj.velocity.x = knockback_force.x * dir
	obj.velocity.y = knockback_force.y  # Hất lên

	elapsed_time = 0.0

func _update(delta: float) -> void:
	elapsed_time += delta

	# Gravity hoạt động như bình thường
	obj.velocity.y += obj.gravity * delta
	obj.move_and_slide()

	# Khi rơi chạm đất hoặc hết thời gian → về idle
	if obj.is_on_floor() and elapsed_time >= hurt_timer:
		_recover_from_hurt()

func _exit() -> void:
	obj.set_detect_and_hurt_collsion(true)
	#obj.can_control = true  # bật lại điều khiển khi thoát hurt
	pass

func _recover_from_hurt():
	fsm.change_state(fsm.states.idle)
