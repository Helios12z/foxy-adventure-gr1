extends EnemyState

var _damage_direction: Vector2

func take_damage(damage_dir: Vector2, _damage: int) -> void:
	_damage_direction = damage_dir
	change_state(fsm.states.hurt)

func _enter() -> void:
	obj.change_animation("hurt")
	obj.velocity = Vector2.ZERO
	timer = 0.4

func _update(delta: float) -> void:
	if update_timer(delta):
		if obj.health <= 0:
			change_state(fsm.states.dead)
		elif obj.can_detect_player():
			change_state(fsm.states.attack)
		else:
			change_state(fsm.states.walk)
