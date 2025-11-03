extends EnemyState


@export var shoot_delay: float = 0.3
var shoot_timer: float = 0.0


func _enter() -> void:
	obj.change_animation("attack")
	shoot_timer = shoot_delay
	timer = 0.5


func _update(delta: float) -> void:
	if shoot_timer > 0:
		shoot_timer -= delta
		if shoot_timer <= 0:
			obj.fire()
	if update_timer(delta):
		change_state(fsm.previous_state)
