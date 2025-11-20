extends WarlordTurtleState

var idle_to_skill_delay: float = 2.1

var is_next_attack: bool = false 

func _enter() -> void:
	timer = idle_to_skill_delay
	obj.change_animation("idle") 

func _update(delta: float) -> void:
	if update_timer(delta):
		if not is_next_attack: 
			is_next_attack = true 
			fsm.change_state(fsm.states.atk_1)
		else: 
			is_next_attack = false 
			fsm.change_state(fsm.states.atk_2)
