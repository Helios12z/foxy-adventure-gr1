extends EnemyState

var teleport_phase := 0 
var fade_timer := 0.0
var fade_duration := 0.5

const MIN_MOVE := 120.0
const SAFE_MIN := 200.0
const SAFE_MAX := 400.0

var pre_teleport_pause: float = 1.0
var post_teleport_pause: float = 0.25

func _enter() -> void:
	obj.change_animation("idle")
	teleport_phase = 0
	fade_timer = 0.0
	obj.velocity.x = 0.0

	obj.animated_sprite_2d.modulate.a = 1.0
	obj.play_teleport_effect(fade_duration)

func _update(d: float) -> void:
	fade_timer += d

	if teleport_phase == 0:  # Fade out
		var progress = min(fade_timer / fade_duration, 1.0)
		obj.animated_sprite_2d.modulate.a = 1.0 - progress

		if fade_timer >= fade_duration:
			obj._disable_teleport_effect()
			teleport_phase = 1
			fade_timer = 0.0

	elif teleport_phase == 1:  # Pause trước khi dịch chuyển
		if fade_timer >= pre_teleport_pause:
			_teleport_to_new_position()
			teleport_phase = 2
			fade_timer = 0.0

	elif teleport_phase == 2:  # Pause sau khi dịch chuyển
		if fade_timer >= post_teleport_pause:
			teleport_phase = 3
			fade_timer = 0.0
			obj.play_teleport_effect(fade_duration)

	elif teleport_phase == 3:  # Fade in (xuất hiện)
		var progress = min(fade_timer / fade_duration, 1.0)
		obj.animated_sprite_2d.modulate.a = progress

		if fade_timer >= fade_duration:
			_finish_teleport()


func _get_target_player() -> Node2D:
	if "_player_fallback" in obj and is_instance_valid(obj._player_fallback):
		return obj._player_fallback
	return null

func _teleport_to_new_position() -> void:
	var target := _get_target_player()
	if target == null:
		return

	var player_x := target.global_position.x
	var current_x := obj.global_position.x
	var safe_distance := randf_range(SAFE_MIN, SAFE_MAX)

	var left_x  := player_x - safe_distance
	var right_x := player_x + safe_distance

	var cand := left_x
	if absf(right_x - current_x) > absf(left_x - current_x):
		cand = right_x

	if absf(cand - current_x) < MIN_MOVE:
		if cand == left_x: cand = right_x
		else: cand = left_x

	if absf(cand - current_x) < MIN_MOVE:
		var need := MIN_MOVE - absf(cand - current_x)
		var delta := cand - current_x
		var dir := 0.0
		if absf(delta) < 0.001:
			if randf()>0.5: dir = 1.0
			else: dir = -1.0 
		else:
			if delta>0.0: dir = 1.0
			else: dir = -1.0
		cand += dir * need

	obj.global_position.x = cand

	var dir_to_player = sign(player_x - cand)
	if dir_to_player != 0:
		obj.change_direction(int(dir_to_player))

func _finish_teleport() -> void:
	obj.animated_sprite_2d.modulate.a = 1.0
	obj.reset_proximity_timer()
	obj._disable_teleport_effect()
	change_state(fsm.states.walk)

func _exit() -> void:
	obj.animated_sprite_2d.modulate.a = 1.0
	obj._disable_teleport_effect()
