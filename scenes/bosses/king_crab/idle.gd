extends KingCrabState

var wait_time: float = 1.25

func _enter()->void:
	obj.change_animation("idle")
	timer = wait_time

func _update(delta: float)->void:
	timer -= wait_time 
	if timer <= 0: 
		if obj.seen_player:
			change_state(fsm.states.walk)
		else: 
			change_state(fsm.states.idle)
