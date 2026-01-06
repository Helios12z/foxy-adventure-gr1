extends EnemyState

## Return state for Ceiling Spider - returns to origin position

func _enter() -> void:
	obj.change_animation("idle")  # Use idle animation while returning

func _update(delta: float) -> void:
	# Move up to origin
	if obj.move_up(delta):
		# Reached origin
		obj._on_return_complete()

func _exit() -> void:
	pass
