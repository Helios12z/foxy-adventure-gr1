extends WarlordTurtleState

var _cast_duration: float = 0.0

func _enter() -> void:
	obj.change_animation("cast")
	_cast_duration = _get_cast_duration()
	timer = _cast_duration

func _update(d: float) -> void:
	if update_timer(d):
		_spawn_atomic_bomb()
		change_state(fsm.states.stun)

func _get_cast_duration() -> float:
	var anim = obj.animated_sprite_2d
	if anim == null:
		return 0.0

	var frames_res = anim.sprite_frames
	if frames_res == null:
		return 0.0

	var anim_name = anim.animation
	if anim_name == "":
		var names = frames_res.get_animation_names()
		if names.size() == 0:
			return 0.0
		anim_name = names[0]

	var frame_count = frames_res.get_frame_count(anim_name)
	if frame_count <= 0:
		return 0.0

	var fps = frames_res.get_animation_speed(anim_name)
	if fps <= 0.0:
		return 0.0

	return float(frame_count) / fps
