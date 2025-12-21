extends KingCrabState

var boomerang_spawned := false

func _enter() -> void:
	obj.change_animation("atk4_idle")
	boomerang_spawned = false

func _update(d: float) -> void:
	if not boomerang_spawned:
		boomerang_spawned = check_boomerang_formation()

func _exit() -> void:
	pass
