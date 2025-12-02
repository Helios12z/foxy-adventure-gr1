extends FSMState

func _enter() -> void:
    obj.enable_hit_area(false)
    obj.animated_sprite_2d.play("idle")
    timer = obj.show_interval

func _update(delta: float) -> void:
    if update_timer(delta):
        change_state(fsm.states.show)
