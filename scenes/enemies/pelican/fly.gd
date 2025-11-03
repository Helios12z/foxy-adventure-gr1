extends EnemyState

@export var shoot_interval: float = 2.0
var shoot_timer: float = 0.0

func _enter() -> void:
	obj.change_animation("fly")
	shoot_timer = shoot_interval

func _update(delta):
	obj.velocity.x = obj.direction * 100
	if _should_turn_around():
		obj.turn_around()
	if shoot_timer > 0:
		shoot_timer -= delta
		if shoot_timer <= 0:
			change_state(fsm.states.attack)


func _should_turn_around() -> bool:
	if obj.is_touch_wall():
		return true
	return false
