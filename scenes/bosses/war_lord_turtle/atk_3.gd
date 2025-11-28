extends WarlordTurtleState

const LOCK_WARNING_TIME := 0.1
const POST_ATTACK_STUN_DELAY := 0.25

var _locked := false
var _rocket_spawned := false
var _warning_timer := 0.0
var _post_attack_timer := 0.0

func _enter() -> void:
	_locked = false
	_rocket_spawned = false
	_warning_timer = 0.0
	_post_attack_timer = 0.0

	obj.change_animation("atk_3")

	set_target_lock_visible(true)
	obj.warning.play()
	follow_target_lock_to_player()

	if obj.target_lock_effect:
		obj.target_lock_effect.frame = 0
		obj.target_lock_effect.play()
		if not obj.target_lock_effect.animation_finished.is_connected(_on_lock_anim_finished):
			obj.target_lock_effect.animation_finished.connect(_on_lock_anim_finished)


func _update(delta: float) -> void:
	obj._update_facing()

	if not _locked:
		follow_target_lock_to_player()
	else:
		if obj.target_lock_effect:
			obj.target_lock_effect.global_position = _atk3_locked_pos

		if not _rocket_spawned:
			_warning_timer += delta
			if _warning_timer >= LOCK_WARNING_TIME:
				_rocket_spawned = true
				obj.missile_launch.play()
				obj.warning.stop()
				spawn_atk3_rocket_from_locked_pos()
				set_target_lock_visible(false)
		else:
			_post_attack_timer += delta
			if _post_attack_timer >= POST_ATTACK_STUN_DELAY:
				fsm.change_state(fsm.states.stun)


func _exit() -> void:
	set_target_lock_visible(false)

	if obj.target_lock_effect and obj.target_lock_effect.animation_finished.is_connected(_on_lock_anim_finished):
		obj.target_lock_effect.animation_finished.disconnect(_on_lock_anim_finished)


func _on_lock_anim_finished() -> void:
	if _locked:
		return

	freeze_target_lock_position()  
	_locked = true

	if obj.target_lock_effect:
		obj.target_lock_effect.stop()

		#force end at last frame
		var frames = obj.target_lock_effect.sprite_frames
		if frames:
			var anim_name = obj.target_lock_effect.animation
			var last_idx = frames.get_frame_count(anim_name) - 1
			if last_idx >= 0:
				obj.target_lock_effect.frame = last_idx
