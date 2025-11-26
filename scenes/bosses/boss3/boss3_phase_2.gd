extends EnemyState

var _running := false
var _rng := RandomNumberGenerator.new()

func _enter() -> void:
	_rng.randomize()
	_running = true
	_run_pattern_phase2()

func _exit() -> void:
	_running = false

func _update(delta: float) -> void:
	if obj.health <= 0:
		change_state(fsm.states.dead)
		return


func _run_pattern_phase2() -> void:
	await get_tree().process_frame

	while _running and obj.health > 0:
		var pattern_type := _rng.randi_range(0, 1)

		if pattern_type == 0:
			await obj.do_vase_water()
			await get_tree().create_timer(0.3).timeout
			await obj.do_eruption_wave()
			await get_tree().create_timer(0.2).timeout
			await obj.do_water_ball()
		else:
			await obj.do_water_pagoda()
			await get_tree().create_timer(0.2).timeout
			await obj.do_water_pillar()
			await get_tree().create_timer(0.2).timeout
			await obj.do_water_ball()

		await get_tree().create_timer(0.2).timeout
