extends WaterPrietestState

var _death_done := false

func _enter() -> void:
	obj.velocity = Vector2.ZERO
	obj.movement_speed = 0.0

	if obj.hit_area_2d:
		obj.hit_area_2d.monitoring = false
		obj.hit_area_2d.monitorable = false

	if obj.has_node("Direction/HurtArea2D"):
		var hurt_area := obj.get_node("Direction/HurtArea2D") as Area2D
		if hurt_area:
			hurt_area.monitoring = false
			hurt_area.monitorable = false

	if obj.camera:
		obj.camera.camera_shake(0.4, 24)

	obj.phase_2.stop()
	
	obj.flash_hurt(
		0.4,
		4,
		Color(1, 1, 1, 1)
	)

	obj._original_time_scale = Engine.time_scale
	Engine.time_scale = 0.15

	var tw := obj.create_tween()
	tw.tween_interval(0.6)
	tw.tween_callback(Callable(self, "_on_death_cinematic_finished"))

func _on_death_cinematic_finished() -> void:
	if _death_done:
		return
	_death_done = true

	Engine.time_scale = obj._original_time_scale

	var tw := obj.create_tween()
	tw.tween_interval(0.6)
	tw.tween_callback(Callable(self, "_final_remove"))

func _final_remove() -> void:
	obj.queue_free()
