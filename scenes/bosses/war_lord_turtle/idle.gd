extends WarlordTurtleState

var idle_to_skill_delay: float = 2.75
var is_next_attack: bool = false 
var first_attack: bool = true 

func _enter() -> void:
	timer = idle_to_skill_delay
	obj.change_animation("idle") 

func _update(delta: float) -> void:
	if obj.seen_player and first_attack:
		first_attack = false 
		if not is_next_attack: 
			is_next_attack = true 
			fsm.change_state(fsm.states.atk_1)
		else: 
			is_next_attack = false 
			fsm.change_state(fsm.states.atk_2)
	if update_timer(delta):
		if not obj.seen_player:
			fsm.change_state(fsm.states.idle)
		else:
			if not is_next_attack: 
				is_next_attack = true 
				fsm.change_state(fsm.states.atk_1)
			else: 
				is_next_attack = false 
				fsm.change_state(fsm.states.atk_2)
