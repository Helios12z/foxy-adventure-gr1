extends EnemyState

## Idle state for Ceiling Spider - waits for player detection

func _enter() -> void:
	obj.change_animation("idle")
	obj.velocity = Vector2.ZERO

func _update(delta: float) -> void:
	# Detection is handled in ceiling_spider.gd
	pass
