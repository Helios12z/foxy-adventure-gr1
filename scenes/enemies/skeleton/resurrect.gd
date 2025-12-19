extends EnemyState

var sprite: AnimatedSprite2D

func _enter() -> void:
	obj.change_animation("resurrect")
	sprite = obj.animated_sprite_2d
	await sprite.animation_finished
	obj.is_dead = false
	obj.finished_in_temporary_dead = false
	obj.is_in_temporary_dead = false
	obj.health = obj.max_health
	obj._update_health_bar_after_damage()
	obj.reset_healthbar_visual()
	fsm.change_state(fsm.states.idle)
