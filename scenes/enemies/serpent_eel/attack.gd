extends EnemyState

func _enter() -> void:
    obj.change_animation("attack")
    obj.velocity.x = 0
    timer = 1.0

func _update(delta: float) -> void:
    if update_timer(delta):
        change_state(fsm.states.attacking)
