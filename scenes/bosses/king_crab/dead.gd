extends KingCrabState

var _death_done := false

func _enter() -> void:
	obj.velocity = Vector2.ZERO
	if obj.hurt_collision_shape_2d:
		obj.hurt_collision_shape_2d.disabled = true
	if obj.hit_collision_shape_2d:
		obj.hit_collision_shape_2d.disabled = true

	if obj.camera:
		obj.camera.camera_shake(0.4, 24)
	
	obj.roar.play()

	if obj.boss_music and obj.boss_music.playing:
		obj.boss_music.stop()

	obj.flash_hurt(
		obj.phase2_flash_duration,
		obj.phase2_flash_blinks,
		Color(1, 1, 1, 1)
	)

	obj._original_time_scale = Engine.time_scale
	Engine.time_scale = obj.phase2_slowmo_scale

	var tw := obj.create_tween()
	tw.tween_interval(obj.phase2_slowmo_duration)
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
