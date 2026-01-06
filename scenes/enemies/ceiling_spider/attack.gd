extends EnemyState

## Attack state for Ceiling Spider - drops down to attack player

var elapsed: float = 0.0
var collision_enabled: bool = false
var reached_bottom: bool = false
var wait_timer: float = 0.0

const COLLISION_DELAY: float = 0.1  # Delay trước khi bật collision
const WAIT_BEFORE_RETURN: float = 0.5  # Đợi 0.5s trước khi return

func _enter() -> void:
	obj.change_animation("attack")
	elapsed = 0.0
	collision_enabled = false
	reached_bottom = false
	wait_timer = 0.0
	
	# Tắt collision mask với map khi bắt đầu
	obj.set_collision_mask_value(1, false)

func _update(delta: float) -> void:
	elapsed += delta
	
	# Bật collision mask sau 0.1s
	if not collision_enabled and elapsed >= COLLISION_DELAY:
		collision_enabled = true
		obj.set_collision_mask_value(1, true)  # Layer 1 = environment/map
	
	# Nếu chưa chạm đáy, tiếp tục rơi
	if not reached_bottom:
		if obj.move_down(delta):
			# Chạm map hoặc đạt max distance -> đợi 0.5s rồi return
			reached_bottom = true
			wait_timer = 0.0
	else:
		# Đã ở đáy, đợi 0.5s rồi return
		wait_timer += delta
		if wait_timer >= WAIT_BEFORE_RETURN:
			obj._start_return()

func _exit() -> void:
	# Tắt collision mask khi exit attack state
	obj.set_collision_mask_value(1, false)
