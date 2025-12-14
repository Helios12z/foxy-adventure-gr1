extends KingCrabState

var _death_done := false
var _dialogue_started := false

func _enter() -> void:
	obj.velocity = Vector2.ZERO
	if obj.hurt_collision_shape_2d:
		obj.hurt_collision_shape_2d.disabled = true
	if obj.hit_collision_shape_2d:
		obj.hit_collision_shape_2d.disabled = true

	if obj.camera:
		obj.camera.camera_shake(0.4, 24)

	obj.roar.play()

	obj.phase_2.stop()

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

	# Play sleep/lie down animation
	obj.animated_sprite_2d.play("sleep")

	# Wait a moment before starting dialogue
	var tw := obj.create_tween()
	tw.tween_interval(0.3)
	tw.tween_callback(Callable(self, "_start_death_dialogue"))


func _start_death_dialogue() -> void:
	if _dialogue_started:
		return
	_dialogue_started = true

	# Start the death dialogue timeline
	Dialogic.start("king_crab_death")
	Dialogic.timeline_ended.connect(_on_dialogue_finished)


func _on_dialogue_finished() -> void:
	Dialogic.timeline_ended.disconnect(_on_dialogue_finished)

	# Wait a bit before removing the boss
	var tw := obj.create_tween()
	tw.tween_interval(0.6)
	tw.tween_callback(Callable(self, "_final_remove"))


func _final_remove() -> void:
	obj.queue_free()
