extends WaterPrietestState

var hurt_time: float = 0.5

func _enter() -> void:
	obj.change_animation("hurt")
	timer = hurt_time

func _update( _delta ):
	if update_timer(_delta):
		# Choose attack based on current phase
		var attack_table = []
		if obj.in_phase2:
			attack_table = [
				[fsm.states.atk_1, 0.1],
				[fsm.states.atk_2, 0.4],
				[fsm.states.atk_3, 0.7],
				[fsm.states.atk_super, 0.95],
			]
		else:
			attack_table = [
				[fsm.states.atk_1, 0.5],
				[fsm.states.atk_2, 0.5],
			]

		# Select attack based on random chance
		var rand_val = randf()
		for attack_info in attack_table:
			if rand_val <= attack_info[1]:
				change_state(attack_info[0])
				return
