extends EnemyState

@onready var delay_time = 0.2

func _enter() -> void:
	obj.change_animation("walk")
	timer = 0.7

func _update(delta):
	if obj.can_detect_player():
		change_state(fsm.states.attack)
	elif update_timer(delta):
		change_state(fsm.states.walk)
