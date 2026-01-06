extends WaterPrietestState

var _death_done := false
var _dialogue_started := false

func _enter() -> void:
	obj.velocity = Vector2.ZERO
	obj.movement_speed = 0.0

	var hit_area = obj.get_node_or_null("Direction/HitArea2D")
	if hit_area:
		hit_area.monitoring = false
		hit_area.monitorable = false

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

	# Play idle/sleep animation if available
	if obj.animated_sprite_2d.sprite_frames.has_animation("sleep"):
		obj.animated_sprite_2d.play("sleep")
	else:
		obj.animated_sprite_2d.play("idle")

	# Wait a moment before starting dialogue
	var tw := obj.create_tween()
	tw.tween_interval(0.3)
	tw.tween_callback(Callable(self, "_start_death_dialogue"))


func _start_death_dialogue() -> void:
	if _dialogue_started:
		return
	_dialogue_started = true

	# Pause boss AI during dialogue
	obj.in_dialogue = true

	# Pause player during dialogue
	var player = obj.get_tree().get_first_node_in_group("Player")
	if player and player.has_method("set_can_move"):
		player.set_can_move(false)

	# Start the death dialogue timeline
	Dialogic.start("water_priestess_death")
	Dialogic.timeline_ended.connect(_on_dialogue_finished)


func _on_dialogue_finished() -> void:
	Dialogic.timeline_ended.disconnect(_on_dialogue_finished)

	# Resume boss AI (not that it matters, boss is dying)
	obj.in_dialogue = false

	# Resume player movement
	var player = obj.get_tree().get_first_node_in_group("Player")
	if player and player.has_method("set_can_move"):
		player.set_can_move(true)

	# Trigger platform transition (floating platforms disappear, rect platform reappears)
	_trigger_platform_transition()

	# Wait a bit before removing the boss
	var tw := obj.create_tween()
	tw.tween_interval(0.6)
	tw.tween_callback(Callable(self, "_final_remove"))


func _final_remove() -> void:
	obj.queue_free()


func _trigger_platform_transition() -> void:
	# Get the platform controller from the level
	var stage = GameManager.current_stage
	if not stage:
		return

	if stage.has_node("World/BossPlatformController"):
		var platform_controller = stage.get_node("World/BossPlatformController")
		if platform_controller and platform_controller.has_method("return_platform_after_boss_dead"):
			platform_controller.return_platform_after_boss_dead()
