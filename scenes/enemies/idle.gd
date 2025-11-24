extends EnemyState

@onready var delay_time = 0.2

func _enter() -> void:
	obj.change_animation("idle")
	timer = 0.7

func _update(delta):
	if update_timer(delta):
		change_state(fsm.states.walk)
