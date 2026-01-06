extends KingCrabState

var _death_done := false
var _dialogue_started := false

func _enter() -> void:
	obj.velocity = Vector2.ZERO
	if obj.hurt_collision_shape_2d:
		obj.hurt_collision_shape_2d.disabled = true
	if obj.hit_collision_shape_2d:
		obj.hit_collision_shape_2d.disabled = true

	# Xóa tất cả minions khi King Crab chết
	_remove_all_minions()

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

	# Pause boss AI during dialogue
	obj.in_dialogue = true

	# Pause player during dialogue
	var player = obj.get_tree().get_first_node_in_group("Player")
	if player and player.has_method("set_can_move"):
		player.set_can_move(false)

	# Start the death dialogue timeline
	Dialogic.start("king_crab_death")
	Dialogic.timeline_ended.connect(_on_dialogue_finished)


func _on_dialogue_finished() -> void:
	Dialogic.timeline_ended.disconnect(_on_dialogue_finished)

	# Resume boss AI (not that it matters, boss is dying)
	obj.in_dialogue = false

	# Resume player movement
	var player = obj.get_tree().get_first_node_in_group("Player")
	if player and player.has_method("set_can_move"):
		player.set_can_move(true)

	# Trigger platform fall after boss is freed (platform controller handles everything)
	_trigger_platform_sequence()

	# Remove the boss immediately
	_final_remove()


func _final_remove() -> void:
	obj.queue_free()


func _trigger_platform_sequence() -> void:
	# Get the platform controller from the level
	var stage = GameManager.current_stage
	if not stage:
		return

	if stage.has_node("World/BossPlatformController"):
		var platform_controller = stage.get_node("World/BossPlatformController")
		if platform_controller and platform_controller.has_method("return_platform_after_boss_dead_delayed"):
			# This function will wait for boss to be freed, then fall, then spawn chest
			platform_controller.return_platform_after_boss_dead_delayed(obj)


func _spawn_chest() -> void:
	# Get the chest from the level
	var stage = GameManager.current_stage
	if not stage:
		return

	if stage.has_method("_spawn_chest"):
		stage._spawn_chest()

func _remove_all_minions() -> void:
	# Lấy tất cả minions trong group và xóa chúng
	var minions = obj.get_tree().get_nodes_in_group("king_crab_minion")
	for minion in minions:
		if is_instance_valid(minion):
			minion.queue_free()
