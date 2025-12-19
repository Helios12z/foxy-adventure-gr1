extends EnemyState

var sprite: AnimatedSprite2D

func _enter() -> void:
	obj.health = obj.max_health
	obj.change_animation("resurrect")
	sprite = obj.animated_sprite_2d
	await sprite.animation_finished
	obj.velocity.x = 0
	obj._update_health_bar_after_damage()
	fsm.change_state(fsm.states.idle)
