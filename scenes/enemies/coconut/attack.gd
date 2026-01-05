extends EnemyState

var shoot_timer: float = 0.0
var shoot_interval: float = 1.0

func _enter() -> void:
	obj.change_animation("attack")
	obj.velocity.x = 0
	shoot_timer = 0.0
	# Shoot immediately on enter
	obj.shoot_bullet()

func _update(delta: float) -> void:
	shoot_timer += delta

	if shoot_timer >= shoot_interval:
		obj.shoot_bullet()
		shoot_timer = 0.0

	# Check if player is still detected
	if not obj.can_detect_player():
		change_state(fsm.states.walk)
