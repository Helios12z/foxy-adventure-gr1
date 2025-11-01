extends EnemyState
func _enter() -> void:
	timer=0.25
	obj.change_animation("atk1_recover")

func _update(d: float) -> void:
	timer -= d
	if timer <= 0.0:
		change_state(fsm.states.walk)

func _exit() -> void:
	obj.toggle_next_attack()   # ATK1 xong → lượt kế là ATK2
