extends EnemyState

func _enter() -> void:
	obj.set_physics_process(false)
	timer = 1.0

func _update(d: float) -> void:
	if update_timer(d):
		obj.queue_free()
