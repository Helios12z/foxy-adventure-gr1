extends EnemyState

var hit_started := false

func _enter() -> void:
	obj.change_animation("attack")
	obj.velocity.x = 0
	timer = 1.0
	hit_started = false

func _exit() -> void:
	obj.set_hit_collision(false)

func _update(delta: float) -> void:
	var sprite = obj.animated_sprite_2d
	if not hit_started \
		and sprite.animation == "attack" \
		and sprite.frame >= 6:
		obj.set_hit_collision(true)
		hit_started = true

	if update_timer(delta):
		if obj.can_detect_player():
			if not obj.is_in_attack_scope():
				change_state(fsm.states.chase)
		else:
			change_state(fsm.states.idle)
