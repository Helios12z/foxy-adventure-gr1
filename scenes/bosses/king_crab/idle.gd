extends KingCrabState

var wait_time: float = 0.5

func _enter()->void:
	obj.change_animation("idle")
	timer = wait_time

func _update(delta: float)->void:
	if update_timer(delta):
		if obj.seen_player:
			change_state(fsm.states.walk)
		else: 
			change_state(fsm.states.idle)
