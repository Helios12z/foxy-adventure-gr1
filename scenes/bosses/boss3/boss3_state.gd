extends EnemyState

@export var phase2_health_threshold: float = 0.5

var _running := false
var _rng := RandomNumberGenerator.new()

func _enter() -> void:
	_rng.randomize()
	_running = true
	_run_pattern()

func _exit() -> void:
	_running = false

func _update(delta: float) -> void:
	if obj.health <= obj.max_health * phase2_health_threshold:
		change_state(fsm.states.phase2)


func _run_pattern() -> void:
	await get_tree().process_frame

	while _running and obj.health > obj.max_health * phase2_health_threshold:
		var skills: Array[Callable] = [
			Callable(obj, "do_eruption_wave"),
			Callable(obj, "do_water_ball"),
			Callable(obj, "do_vase_water")
		]

		var idx := _rng.randi_range(0, skills.size() - 1)
		var skill := skills[idx]

		await skill.call()
		await get_tree().create_timer(0.4).timeout
