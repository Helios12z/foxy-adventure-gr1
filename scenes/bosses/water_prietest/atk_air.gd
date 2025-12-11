extends WaterPrietestState

var _time_in_state: float = 0.0
const MAX_AIR_ATTACK_TIME := 0.6 

func _enter() -> void:
	_time_in_state = 0.0
	obj.change_animation("atk_air")
	obj.velocity.y += 50.0

func _update(delta: float) -> void:
	_time_in_state += delta

	if obj.animated_sprite_2d.animation == "atk_air" \
	and not obj.animated_sprite_2d.is_playing():
		change_state(fsm.previous_state)
		return

	if _time_in_state >= MAX_AIR_ATTACK_TIME:
		change_state(fsm.previous_state)
		return
