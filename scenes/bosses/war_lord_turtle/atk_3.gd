extends WarlordTurtleState

const LOCK_WARNING_TIME := 0.25
const POST_ATTACK_STUN_DELAY := 0.35

var _locked := false
var _rocket_spawned := false
var _warning_timer := 0.0
var _post_attack_timer := 0.0

func _enter() -> void:
	_locked = false
	_rocket_spawned = false
	_warning_timer = 0.0
	_post_attack_timer = 0.0

	# Anim thân boss
	obj.change_animation("atk_3")

	# Bật target lock + cho nó bám player ngay từ frame đầu
	set_target_lock_visible(true)
	follow_target_lock_to_player()

	# Chạy animation lock của target_lock_effect
	if obj.target_lock_effect:
		obj.target_lock_effect.play()
		# Khi anim lock chạy hết -> lock cứng vị trí
		if not obj.target_lock_effect.animation_finished.is_connected(_on_lock_anim_finished):
			obj.target_lock_effect.animation_finished.connect(_on_lock_anim_finished)


func _update(delta: float) -> void:
	obj._update_facing()

	if not _locked:
		# Trong khi anim lock còn đang chạy → bám theo player
		follow_target_lock_to_player()
	else:
		# Đã lock rồi → giữ nguyên tại _atk3_locked_pos
		if obj.target_lock_effect:
			obj.target_lock_effect.global_position = _atk3_locked_pos

		if not _rocket_spawned:
			# Phase warning: cho player 0.25s để né
			_warning_timer += delta
			if _warning_timer >= LOCK_WARNING_TIME:
				_rocket_spawned = true
				spawn_atk3_rocket_from_locked_pos()
				# Spawn xong thì tắt luôn target lock cho gọn
				set_target_lock_visible(false)
		else:
			# Rocket đã được bắn -> chờ thêm chút rồi sang stun
			_post_attack_timer += delta
			if _post_attack_timer >= POST_ATTACK_STUN_DELAY:
				fsm.change_state(fsm.states.stun)


func _exit() -> void:
	# Đảm bảo effect tắt khi rời state
	set_target_lock_visible(false)

	if obj.target_lock_effect and obj.target_lock_effect.animation_finished.is_connected(_on_lock_anim_finished):
		obj.target_lock_effect.animation_finished.disconnect(_on_lock_anim_finished)


func _on_lock_anim_finished() -> void:
	# Anim target lock chạy xong → chốt vị trí lock
	if _locked:
		return

	freeze_target_lock_position()  # helper trong WarlordTurtleState -> set _atk3_locked_pos
	_locked = true

	if obj.target_lock_effect:
		# Dừng anim
		obj.target_lock_effect.stop()

		# Ép cho nó đứng ở frame cuối cùng, tránh nhảy về frame 0
		var frames = obj.target_lock_effect.sprite_frames
		if frames:
			var anim_name = obj.target_lock_effect.animation
			var last_idx = frames.get_frame_count(anim_name) - 1
			if last_idx >= 0:
				obj.target_lock_effect.frame = last_idx
