extends WaterPrietestState

var _time_in_state: float = 0.0
const MAX_AIR_ATTACK_TIME := 0.6  # 0.5–0.7s tùy độ dài anim

func _enter() -> void:
	_time_in_state = 0.0
	obj.change_animation("atk_air")
	# Cho nó tiếp tục rơi nhẹ xuống, nhưng gravity chính vẫn do BaseCharacter xử lý
	obj.velocity.y += 50.0

func _update(delta: float) -> void:
	_time_in_state += delta

	# 1) Nếu animation atk_air đã chạy xong (và không loop) → AnimatedSprite2D sẽ dừng
	if obj.animated_sprite_2d.animation == "atk_air" \
	and not obj.animated_sprite_2d.is_playing():
		change_state(fsm.states.fall)
		return

	# 2) Fallback: quá thời gian MAX_AIR_ATTACK_TIME vẫn chưa rơi thì ép sang fall
	if _time_in_state >= MAX_AIR_ATTACK_TIME:
		change_state(fsm.states.fall)
		return
