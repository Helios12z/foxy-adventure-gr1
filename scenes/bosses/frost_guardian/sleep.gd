extends EnemyState

func _enter() -> void:
	obj.change_animation("sleep")
	obj.gravity = 0
	obj.velocity.y = 0
