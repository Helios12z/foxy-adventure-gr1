extends WarlordTurtleState

var _rocket1_spawned := false
var _rocket2_spawned := false
var _rocket3_spawned := false
var _rocket4_spawned := false

# Lưu ý: frame index Godot là 0-based.
# Nếu trong editor bạn thấy frame 4,5,7,8 (đếm từ 0) thì giữ như này.
# Nếu bạn đang nghĩ "frame thứ 4" (đếm từ 1) thì phải trừ 1.
const ROCKET1_FRAME := 4
const ROCKET2_FRAME := 5
const ROCKET3_FRAME := 7
const ROCKET4_FRAME := 8

func _enter() -> void:
	_rocket1_spawned = false
	_rocket2_spawned = false
	_rocket3_spawned = false
	_rocket4_spawned = false

	obj.change_animation("atk_2")

	if not obj.animated_sprite_2d.frame_changed.is_connected(_on_frame_changed):
		obj.animated_sprite_2d.frame_changed.connect(_on_frame_changed)
	if not obj.animated_sprite_2d.animation_finished.is_connected(_on_anim_finished):
		obj.animated_sprite_2d.animation_finished.connect(_on_anim_finished)

func _update(delta: float) -> void:
	obj._update_facing()

func _exit() -> void:
	if obj.animated_sprite_2d.frame_changed.is_connected(_on_frame_changed):
		obj.animated_sprite_2d.frame_changed.disconnect(_on_frame_changed)
	if obj.animated_sprite_2d.animation_finished.is_connected(_on_anim_finished):
		obj.animated_sprite_2d.animation_finished.disconnect(_on_anim_finished)

func _on_frame_changed() -> void:

	# Chỉ quan tâm khi anim hiện tại là "atk_2"
	if obj.animated_sprite_2d.animation != "atk_2":
		return

	var f = obj.animated_sprite_2d.frame

	# Rocket 1: frame 4, gun 1, target A (index 0)
	if not _rocket1_spawned and f == ROCKET1_FRAME:
		_rocket1_spawned = true
		spawn_rocket_from_index(0, 0)

	# Rocket 2: frame 5, gun 2, target B (index 1)
	if not _rocket2_spawned and f == ROCKET2_FRAME:
		_rocket2_spawned = true
		spawn_rocket_from_index(1, 1)

	# Rocket 3: frame 7, gun 1, target C (index 2)
	if not _rocket3_spawned and f == ROCKET3_FRAME:
		_rocket3_spawned = true
		spawn_rocket_from_index(2, 0)

	# Rocket 4: frame 8, gun 2, target D (index 3)
	if not _rocket4_spawned and f == ROCKET4_FRAME:
		_rocket4_spawned = true
		spawn_rocket_from_index(3, 1)

func _on_anim_finished() -> void:
	fsm.change_state(fsm.states.stun)
