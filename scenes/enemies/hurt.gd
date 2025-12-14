extends EnemyState

var _skew_tween: Tween
var _direction_node: Node2D

func _enter():
	obj.change_animation("hit")
	timer = 0.5

	# Get Direction node for visual effects
	if obj.has_node("Direction"):
		_direction_node = obj.get_node("Direction")

	# Apply knockback with smooth knock-up
	_apply_knockback()

	# Apply skew effect for impact feel
	_apply_skew_effect()

func _update(delta: float):
	if update_timer(delta):
		_cleanup_effects()

		if obj.health <= 0:
			change_state(fsm.states.dead)
		else:
			if obj.has_meta("force_hurt_return_state"):
				var target := str(obj.get_meta("force_hurt_return_state"))
				obj.remove_meta("force_hurt_return_state")
				if target == "walk":
					change_state(fsm.states.walk)
					return
				if target == "idle":
					change_state(fsm.states.idle)
					return
			change_state(fsm.previous_state)

func _apply_knockback():
	# Horizontal knockback is already applied in EnemyState.take_damage()
	# Here we add vertical knock-up for better feel

	# Only apply upward knockback for enemies with gravity (ground enemies)
	# Flying enemies (gravity = 0) won't fly away when hit
	if obj.gravity > 0:
		# Smooth knock-up with decay
		obj.velocity.y = -150
	else:
		# For flying enemies, add slight recoil backwards
		# The horizontal velocity is already set, just enhance it slightly
		obj.velocity.x *= 1.2

func _apply_skew_effect():
	if _direction_node == null:
		return

	# Kill existing tween if any
	if _skew_tween != null and _skew_tween.is_valid():
		_skew_tween.kill()

	# Create skew animation for impact
	var skew_direction = sign(obj.velocity.x)
	if skew_direction == 0:
		skew_direction = -obj.direction

	_skew_tween = create_tween()
	_skew_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Skew on impact
	_skew_tween.tween_property(_direction_node, "skew", skew_direction * 0.3, 0.1)
	# Return to normal
	_skew_tween.tween_property(_direction_node, "skew", 0.0, 0.3)

func _cleanup_effects():
	# Clean up skew effect
	if _direction_node != null:
		_direction_node.skew = 0.0

	if _skew_tween != null and _skew_tween.is_valid():
		_skew_tween.kill()

func _exit():
	_cleanup_effects()
