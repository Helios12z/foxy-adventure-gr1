extends EnemyState

var warmup_time: float = 2.0   

func _enter() -> void:
	timer = warmup_time

	obj.water.visible = true
	obj.tornado.visible = false

	obj.hit_area_2d.monitoring = false
	# obj.hit_area_2d.monitorable = false

	obj._start_warning_blink(warmup_time, 5)


func _update(delta: float) -> void:
	if update_timer(delta):
		obj._stop_blink()
		change_state(fsm.states.tornado)
