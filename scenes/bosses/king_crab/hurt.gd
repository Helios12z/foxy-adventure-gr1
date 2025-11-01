extends EnemyState

func _enter() -> void:
	if obj.sprite: obj.sprite.play("hurt")
	timer = 0.2

func _update(d: float) -> void:
	if obj.health <= 0: 
		change_state(fsm.states.dead)
		return
	if update_timer(d):
		change_state(fsm.states.walk)
