extends EnemyState

## Attack state for Ceiling Spider - drops down to attack player

var attack_timer: float = 0.0
var attack_duration: float = 0.5  # Time to stay at bottom before returning
var elapsed: float = 0.0
var collision_enabled: bool = false
var reached_bottom: bool = false

const COLLISION_DELAY: float = 0.1  # Delay trước khi bật collision

func _enter() -> void:
	obj.change_animation("attack")
	attack_timer = 0.0
	elapsed = 0.0
	collision_enabled = false
	reached_bottom = false
	
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
			# Chạm map hoặc đạt max distance -> quay về ngay
			reached_bottom = true
			obj._start_return()
	else:
		# Đã ở đáy, đợi rồi return (không cần nữa vì return ngay)
		pass

func _exit() -> void:
	# Tắt collision mask khi exit attack state
	obj.set_collision_mask_value(1, false)
