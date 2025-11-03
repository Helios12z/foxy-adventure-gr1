extends EnemyState

func _enter() -> void:
	obj.velocity.x=0
	timer = 1.0

func _update(d: float) -> void:
	if update_timer(d):
		obj.queue_free()
