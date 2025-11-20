extends WarlordTurtleState

var _spawned_first := false
var _spawned_second := false

const FIRST_CANNON_FRAME := 3
const SECOND_CANNON_FRAME := 4

func _enter() -> void:
	_spawned_first = false
	_spawned_second = false

	obj.change_animation("atk_1")

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
	var f = obj.animated_sprite_2d.frame

	if not _spawned_first and f == FIRST_CANNON_FRAME:
		_spawned_first = true
		_spawn_cannon_1()

	if not _spawned_second and f == SECOND_CANNON_FRAME:
		_spawned_second = true
		_spawn_cannon_2()
		
func _spawn_cannon_1() -> void:
	# trái
	_spawn_bomb(obj.atk_1_shoot_point_1, Vector2.RIGHT)

func _spawn_cannon_2() -> void:
	# phải
	_spawn_bomb(obj.atk_1_shoot_point_2, Vector2.LEFT)
	
func _on_anim_finished() -> void:
	fsm.change_state(fsm.states.idle)
