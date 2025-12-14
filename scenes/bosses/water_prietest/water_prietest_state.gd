extends EnemyState
class_name WaterPrietestState

const SAME_LEVEL_THRESHOLD = 50.0
const DROP_UNDER_X := 12.0
const DROP_EDGE_OUT := 12.0
const NAV_EPS_X := 6.0
const MARKER_Y_UP_PAD := 10.0     
const MARKER_Y_DOWN_PAD := 40.0   
const MARKER_Y_CAP := 70.0     
const MARKER_X_PAD := 10.0

var _jump_target_x: float = 0.0
var _has_reached_peak: bool = false
var _drop_active := false
var _drop_x := 0.0
var _drop_force_x := 0.0
var _last_move_dir_x: int = 1

var _atk_shapes_cached: bool = false
var _atk1_shape_base_size: Vector2
var _atk1_shape_base_position: Vector2
var _atk2_right_shape_base_size: Vector2
var _atk2_right_shape_base_position: Vector2
var _atk2_left_shape_base_size: Vector2
var _atk2_left_shape_base_position: Vector2
var _atk_super_shape_base_size: Vector2
var _atk_super_shape_base_position: Vector2

var _body_shapes_cached: bool = false
var _hit_shape_base_position: Vector2
var _hurt_shape_base_position: Vector2
var _body_shape_base_position: Vector2
		
func _ensure_atk_shapes_cached() -> void:
	if _atk_shapes_cached:
		return
	_atk_shapes_cached = true

	if obj.atk1_collision_shape_2d and obj.atk1_collision_shape_2d.shape is RectangleShape2D:
		var rect := obj.atk1_collision_shape_2d.shape as RectangleShape2D
		_atk1_shape_base_size = rect.size
		_atk1_shape_base_position = obj.atk1_collision_shape_2d.position

	if obj.atk2_collision_shape_2d_right and obj.atk2_collision_shape_2d_right.shape is RectangleShape2D:
		var rect2 := obj.atk2_collision_shape_2d_right.shape as RectangleShape2D
		_atk2_right_shape_base_size = rect2.size
		_atk2_right_shape_base_position = obj.atk2_collision_shape_2d_right.position

	if obj.atk2_collision_shape_2d_left and obj.atk2_collision_shape_2d_left.shape is RectangleShape2D:
		var rect3 := obj.atk2_collision_shape_2d_left.shape as RectangleShape2D
		_atk2_left_shape_base_size = rect3.size
		_atk2_left_shape_base_position = obj.atk2_collision_shape_2d_left.position

	if obj.atk_super_collision_shape_2d and obj.atk_super_collision_shape_2d.shape is CircleShape2D:
		var circle := obj.atk_super_collision_shape_2d.shape as CircleShape2D
		_atk_super_shape_base_size = Vector2(circle.radius * 2.0, circle.radius * 2.0)
		_atk_super_shape_base_position = obj.atk_super_collision_shape_2d.position

func _reset_atk_shapes_to_base() -> void:
	if obj.atk1_collision_shape_2d and obj.atk1_collision_shape_2d.shape is RectangleShape2D:
		var rect := obj.atk1_collision_shape_2d.shape as RectangleShape2D
		rect.size = _atk1_shape_base_size
		obj.atk1_collision_shape_2d.position = _atk1_shape_base_position

	if obj.atk2_collision_shape_2d_right and obj.atk2_collision_shape_2d_right.shape is RectangleShape2D:
		var rect2 := obj.atk2_collision_shape_2d_right.shape as RectangleShape2D
		rect2.size = _atk2_right_shape_base_size
		obj.atk2_collision_shape_2d_right.position = _atk2_right_shape_base_position

	if obj.atk2_collision_shape_2d_left and obj.atk2_collision_shape_2d_left.shape is RectangleShape2D:
		var rect3 := obj.atk2_collision_shape_2d_left.shape as RectangleShape2D
		rect3.size = _atk2_left_shape_base_size
		obj.atk2_collision_shape_2d_left.position = _atk2_left_shape_base_position

	if obj.atk_super_collision_shape_2d and obj.atk_super_collision_shape_2d.shape is CircleShape2D:
		var circle := obj.atk_super_collision_shape_2d.shape as CircleShape2D
		circle.radius = _atk_super_shape_base_size.x * 0.5
		obj.atk_super_collision_shape_2d.position = _atk_super_shape_base_position

func _s() -> AnimatedSprite2D:
	return obj.animated_sprite_2d if obj else null

func _connect_signals(frame_cb: Callable, finished_cb: Callable) -> void:
	var sprite := _s()
	if sprite == null:
		return
	if not sprite.frame_changed.is_connected(frame_cb):
		sprite.frame_changed.connect(frame_cb)
	if not sprite.animation_finished.is_connected(finished_cb):
		sprite.animation_finished.connect(finished_cb)

func _disconnect_signals(frame_cb: Callable, finished_cb: Callable) -> void:
	var sprite := _s()
	if sprite == null:
		return
	if sprite.frame_changed.is_connected(frame_cb):
		sprite.frame_changed.disconnect(frame_cb)
	if sprite.animation_finished.is_connected(finished_cb):
		sprite.animation_finished.disconnect(finished_cb)

func _reset_windup(done_prop: StringName, waiting_prop: StringName) -> void:
	set(done_prop, false)
	set(waiting_prop, false)

func _windup(done_prop: StringName, waiting_prop: StringName, frame: int, trigger: int, t: float, anim := "", check_anim := false) -> void:
	if frame != trigger or get(done_prop) or get(waiting_prop):
		return
	var sprite := _s()
	if sprite == null:
		return
	set(waiting_prop, true)
	sprite.speed_scale = 0.0
	await obj.get_tree().create_timer(t).timeout
	if is_instance_valid(sprite):
		if (not check_anim) or sprite.animation == anim:
			sprite.speed_scale = 1.0
	set(done_prop, true)
	set(waiting_prop, false)

func _set_disabled(list: Array, disabled: bool) -> void:
	for s in list:
		if s:
			s.disabled = disabled

func _play(p, cond := true) -> void:
	if cond and p:
		p.play()

func _rect_scale_keep_left(cs: CollisionShape2D, base_size: Vector2, base_pos: Vector2, sx: float, sy: float, extra := Vector2.ZERO) -> void:
	if cs == null or not (cs.shape is RectangleShape2D):
		return
	var r := cs.shape as RectangleShape2D
	r.size = Vector2(base_size.x * sx, base_size.y * sy)
	cs.position = base_pos + Vector2(base_size.x * (sx - 1.0) * 0.5, 0.0) + extra
	cs.disabled = false

func _atk2_like_part_a(frame: int, final_from: int, final_to: int) -> void:
	_ensure_atk_shapes_cached()
	_reset_atk_shapes_to_base()

	_set_disabled([obj.atk1_collision_shape_2d, obj.atk2_collision_shape_2d_right, obj.atk2_collision_shape_2d_left], true)

	match frame:
		2, 3:
			if obj.atk1_collision_shape_2d:
				obj.atk1_collision_shape_2d.disabled = false
			_play(obj.slash, frame == 2)
		4, 5:
			if obj.atk2_collision_shape_2d_right:
				obj.atk2_collision_shape_2d_right.disabled = false
			_play(obj.slash, frame == 4)
		7:
			_rect_scale_keep_left(obj.atk2_collision_shape_2d_right, _atk2_right_shape_base_size, _atk2_right_shape_base_position, 0.5, 2.0)
			_play(obj.slash)
		9:
			if obj.atk2_collision_shape_2d_left:
				obj.atk2_collision_shape_2d_left.disabled = false
			_play(obj.slash)
		_:
			if frame >= final_from and frame <= final_to:
				_rect_scale_keep_left(obj.atk1_collision_shape_2d, _atk1_shape_base_size, _atk1_shape_base_position, 2.0, 2.0)
				_play(obj.slash, frame == final_from)

	_ensure_body_shapes_cached()
	match frame:
		2:
			_shift_body_shapes(12)
		9:
			_reset_body_shapes_to_base()
		_:
			if frame == final_from:
				_shift_body_shapes(12)

func do_atk1() -> void:
	var sprite := _s()
	if sprite == null:
		return
	_reset_windup(&"_atk1_windup_done", &"_atk1_windup_waiting")
	sprite.speed_scale = 1.0
	_connect_signals(_on_atk1_frame_changed, _on_atk1_anim_finished)

func _on_atk1_frame_changed() -> void:
	var sprite := _s()
	if sprite == null:
		return

	if sprite.animation != "atk_1":
		_set_disabled([obj.atk1_collision_shape_2d], true)
		_reset_body_shapes_to_base()
		return

	var f := sprite.frame
	await _windup(&"_atk1_windup_done", &"_atk1_windup_waiting", f, 1, obj.atk1_windup_time)

	match f:
		2:
			_shift_body_shapes(12)
			_play(obj.slash)
		5:
			_reset_body_shapes_to_base()

	_set_disabled([obj.atk1_collision_shape_2d], not (f == 2 or f == 3))

func _on_atk1_anim_finished() -> void:
	var sprite := _s()
	if sprite == null or sprite.animation != "atk_1":
		return

	_set_disabled([obj.atk1_collision_shape_2d], true)
	sprite.speed_scale = 1.0
	_reset_windup(&"_atk1_windup_done", &"_atk1_windup_waiting")
	_reset_body_shapes_to_base()
	_disconnect_signals(_on_atk1_frame_changed, _on_atk1_anim_finished)

	if obj.fsm:
		obj.fsm.change_state(obj.fsm.states.idle)

func do_atk2() -> void:
	var sprite := _s()
	if sprite == null:
		return

	_reset_windup(&"_atk2_windup_done", &"_atk2_windup_waiting")
	sprite.speed_scale = 1.0
	_ensure_atk_shapes_cached()
	_reset_atk_shapes_to_base()
	_connect_signals(_on_atk2_frame_changed, _on_atk2_anim_finished)

func _on_atk2_frame_changed() -> void:
	var sprite := _s()
	if sprite == null:
		return

	if sprite.animation != "atk_2":
		_reset_body_shapes_to_base()
		_set_disabled([obj.atk1_collision_shape_2d, obj.atk2_collision_shape_2d_right, obj.atk2_collision_shape_2d_left], true)
		return

	var f := sprite.frame
	await _windup(&"_atk2_windup_done", &"_atk2_windup_waiting", f, 1, obj.atk2_windup_time)

	_atk2_like_part_a(f, 14, 17)

	if f == 19:
		_reset_body_shapes_to_base()

func _on_atk2_anim_finished() -> void:
	var sprite := _s()
	if sprite == null or sprite.animation != "atk_2":
		return

	_set_disabled([obj.atk1_collision_shape_2d, obj.atk2_collision_shape_2d_right, obj.atk2_collision_shape_2d_left], true)
	sprite.speed_scale = 1.0
	_reset_windup(&"_atk2_windup_done", &"_atk2_windup_waiting")
	_reset_atk_shapes_to_base()
	_reset_body_shapes_to_base()
	_disconnect_signals(_on_atk2_frame_changed, _on_atk2_anim_finished)

	if obj.fsm:
		obj.fsm.change_state(obj.fsm.states.idle)

func do_atk3() -> void:
	var sprite := _s()
	if sprite == null:
		return

	_reset_windup(&"_atk3_windup_done", &"_atk3_windup_waiting")
	sprite.speed_scale = 1.0
	_ensure_atk_shapes_cached()
	_reset_atk_shapes_to_base()
	_connect_signals(_on_atk3_frame_changed, _on_atk3_anim_finished)

func _on_atk3_frame_changed() -> void:
	var sprite := _s()
	if sprite == null:
		return

	if sprite.animation != "atk_3":
		_set_disabled([obj.atk1_collision_shape_2d, obj.atk2_collision_shape_2d_right, obj.atk2_collision_shape_2d_left, obj.atk3_collision_shape_2d], true)
		return

	var f := sprite.frame
	await _windup(&"_atk3_windup_done", &"_atk3_windup_waiting", f, 1, obj.atk2_windup_time, "atk_3", true)

	if f < 17:
		_atk2_like_part_a(f, 14, 16)
		return

	_ensure_atk_shapes_cached()
	_reset_atk_shapes_to_base()
	_set_disabled([obj.atk1_collision_shape_2d, obj.atk2_collision_shape_2d_right, obj.atk2_collision_shape_2d_left, obj.atk3_collision_shape_2d], true)

	_ensure_body_shapes_cached()
	match f:
		19:
			_shift_body_shapes(20)
		23:
			_shift_body_shapes(12)
		25:
			_reset_body_shapes_to_base()

	match f:
		17:
			if obj.atk3_collision_shape_2d:
				obj.atk3_collision_shape_2d.disabled = false
			_play(obj.slash)
		18:
			if obj.atk2_collision_shape_2d_left and obj.atk2_collision_shape_2d_left.shape is RectangleShape2D:
				var r := obj.atk2_collision_shape_2d_left.shape as RectangleShape2D
				var bs := _atk2_left_shape_base_size
				var bp := _atk2_left_shape_base_position
				r.size = Vector2(bs.x, bs.y * 2.0)
				obj.atk2_collision_shape_2d_left.position = bp + Vector2(bs.x * 0.25, bs.y * 0.5)
				obj.atk2_collision_shape_2d_left.disabled = false
			_play(obj.slash)
		_:
			if f >= 19 and f <= 25 and obj.atk2_collision_shape_2d_right and obj.atk2_collision_shape_2d_right.shape is RectangleShape2D:
				var r2 := obj.atk2_collision_shape_2d_right.shape as RectangleShape2D
				var bs2 := _atk2_right_shape_base_size
				var bp2 := _atk2_right_shape_base_position
				var size := bs2
				var pos := bp2

				if f == 20:
					size.x = bs2.x * 0.7
					pos.x += bs2.x * 0.25
				elif f >= 21:
					size.x = bs2.x
					size.y = bs2.y * 2.0
					pos.x += bs2.x * 1.25
					pos.y -= bs2.y * 0.5

				r2.size = size
				obj.atk2_collision_shape_2d_right.position = pos
				obj.atk2_collision_shape_2d_right.disabled = false

				_play(obj.slash, f == 19)
				_play(obj.water_slash, f == 21)

func _on_atk3_anim_finished() -> void:
	var sprite := _s()
	if sprite == null or sprite.animation != "atk_3":
		return

	_set_disabled([obj.atk1_collision_shape_2d, obj.atk2_collision_shape_2d_right, obj.atk2_collision_shape_2d_left, obj.atk3_collision_shape_2d], true)
	sprite.speed_scale = 1.0
	_reset_windup(&"_atk3_windup_done", &"_atk3_windup_waiting")
	_reset_atk_shapes_to_base()
	_reset_body_shapes_to_base()
	_disconnect_signals(_on_atk3_frame_changed, _on_atk3_anim_finished)

	if obj.fsm:
		obj.fsm.change_state(obj.fsm.states.idle)

func do_atk_super() -> void:
	var sprite := _s()
	if sprite == null:
		return

	_reset_windup(&"_atk_super_windup_done", &"_atk_super_windup_waiting")
	sprite.speed_scale = 1.0
	_ensure_atk_shapes_cached()
	_reset_atk_shapes_to_base()
	_set_disabled([obj.atk_super_collision_shape_2d], true)
	_connect_signals(_on_atk_super_frame_changed, _on_atk_super_anim_finished)

func _on_atk_super_frame_changed() -> void:
	var sprite := _s()
	if sprite == null:
		return

	if sprite.animation != "atk_super":
		_set_disabled([obj.atk_super_collision_shape_2d, obj.atk2_collision_shape_2d_right], true)
		return

	var f := sprite.frame

	_set_disabled([obj.atk_super_collision_shape_2d], true)
	if f >= 5 and f <= 11:
		_reset_atk_shapes_to_base()
		_set_disabled([obj.atk_super_collision_shape_2d], false)
		_play(obj.slash, f == 5)
	elif f == 12:
		_play(obj.water_slash)
	elif f >= 13 and f <= 16:
		if obj.atk_super_collision_shape_2d:
			obj.atk_super_collision_shape_2d.position = _atk_super_shape_base_position + Vector2(0.0, 20.0)

	if obj.atk2_collision_shape_2d_right and obj.atk2_collision_shape_2d_right.shape is RectangleShape2D:
		var r := obj.atk2_collision_shape_2d_right.shape as RectangleShape2D
		var bs := _atk2_right_shape_base_size
		var bp := _atk2_right_shape_base_position
		r.size = bs
		obj.atk2_collision_shape_2d_right.position = bp
		obj.atk2_collision_shape_2d_right.disabled = true

		match f:
			12:
				r.size = Vector2(bs.x * 2.0, bs.y)
				obj.atk2_collision_shape_2d_right.position = bp + Vector2(bs.x * 0.5, 0.0)
				obj.atk2_collision_shape_2d_right.disabled = false
			13, 14, 15, 16:
				r.size = Vector2(bs.x * 2.0, bs.y * 2.0)
				obj.atk2_collision_shape_2d_right.position = Vector2(bp.x + bs.x * 0.5, bp.y - bs.y * 0.5)
				obj.atk2_collision_shape_2d_right.disabled = false
			21:
				r.size = Vector2(bs.x * 2.0, bs.y * 2.0)
				obj.atk2_collision_shape_2d_right.position = Vector2(bp.x + bs.x * 0.5, bp.y - bs.y * 0.5)
				obj.atk2_collision_shape_2d_right.disabled = false
			_:
				if f >= 22 and f <= 29:
					r.size = Vector2(bs.x * 2.0, bs.y)
					obj.atk2_collision_shape_2d_right.position = Vector2(bp.x + bs.x * 0.5, bp.y + bs.y * 0.25)
					obj.atk2_collision_shape_2d_right.disabled = false

func _on_atk_super_anim_finished() -> void:
	var sprite := _s()
	if sprite == null or sprite.animation != "atk_super":
		return

	_set_disabled([obj.atk_super_collision_shape_2d], true)
	sprite.speed_scale = 1.0
	_reset_windup(&"_atk_super_windup_done", &"_atk_super_windup_waiting")
	_reset_atk_shapes_to_base()
	_disconnect_signals(_on_atk_super_frame_changed, _on_atk_super_anim_finished)

	if obj.fsm:
		obj.fsm.change_state(obj.fsm.states.idle)

func do_atk_air() -> void:
	var sprite := _s()
	if sprite == null:
		return

	_reset_windup(&"_atk_air_windup_done", &"_atk_air_windup_waiting")
	sprite.speed_scale = 1.0
	_ensure_atk_shapes_cached()
	_reset_atk_shapes_to_base()
	_set_disabled([obj.atk1_collision_shape_2d], true)
	_connect_signals(_on_atk_air_frame_changed, _on_atk_air_anim_finished)

func _on_atk_air_frame_changed() -> void:
	var sprite := _s()
	if sprite == null:
		return

	if sprite.animation != "atk_air":
		_set_disabled([obj.atk1_collision_shape_2d], true)
		return

	var f := sprite.frame
	await _windup(&"_atk_air_windup_done", &"_atk_air_windup_waiting", f, 2, obj.atk_air_windup_time, "atk_air", true)

	if f >= 3 and f <= 5 and obj.atk1_collision_shape_2d and obj.atk1_collision_shape_2d.shape is RectangleShape2D:
		var r := obj.atk1_collision_shape_2d.shape as RectangleShape2D
		var bs := _atk1_shape_base_size
		var bp := _atk1_shape_base_position
		r.size = Vector2(bs.x * 1.5, bs.y * 1.75)
		obj.atk1_collision_shape_2d.position = bp + Vector2(10, 0)
		obj.atk1_collision_shape_2d.disabled = false
		_play(obj.slash, f == 3)
	else:
		_set_disabled([obj.atk1_collision_shape_2d], true)

func _on_atk_air_anim_finished() -> void:
	var sprite := _s()
	if sprite == null or sprite.animation != "atk_air":
		return

	_set_disabled([obj.atk1_collision_shape_2d], true)
	sprite.speed_scale = 1.0
	_reset_windup(&"_atk_air_windup_done", &"_atk_air_windup_waiting")
	_reset_atk_shapes_to_base()
	_disconnect_signals(_on_atk_air_frame_changed, _on_atk_air_anim_finished)

	change_state(fsm.previous_state)

func _ensure_body_shapes_cached() -> void:
	if _body_shapes_cached:
		return
	_body_shapes_cached = true
	if obj.hit_collision_shape_2d:
		_hit_shape_base_position = obj.hit_collision_shape_2d.position
	if obj.hurt_collision_shape_2d:
		_hurt_shape_base_position = obj.hurt_collision_shape_2d.position
	if obj.collision_shape_2d:
		_body_shape_base_position = obj.collision_shape_2d.position

func _shift_body_shapes(offset_x: float) -> void:
	_ensure_body_shapes_cached()
	if obj.hit_collision_shape_2d:
		obj.hit_collision_shape_2d.position = _hit_shape_base_position + Vector2(offset_x, 0.0)
	if obj.hurt_collision_shape_2d:
		obj.hurt_collision_shape_2d.position = _hurt_shape_base_position + Vector2(offset_x, 0.0)
	if obj.collision_shape_2d:
		obj.collision_shape_2d.position = _body_shape_base_position + Vector2(offset_x, 0.0)

func _reset_body_shapes_to_base() -> void:
	if not _body_shapes_cached:
		return
	if obj.hit_collision_shape_2d:
		obj.hit_collision_shape_2d.position = _hit_shape_base_position
	if obj.hurt_collision_shape_2d:
		obj.hurt_collision_shape_2d.position = _hurt_shape_base_position
	if obj.collision_shape_2d:
		obj.collision_shape_2d.position = _body_shape_base_position

func _all_markers() -> Array:
	return get_tree().get_nodes_in_group("jump_markers")

func _marker_for_pos(pos: Vector2) -> JumpMarker2D:
	var best: JumpMarker2D = null
	var best_score := INF

	for m in obj.jump_markers:
		var jm := m as JumpMarker2D
		if jm == null or not jm.is_active:
			continue

		var half = jm.platform_size * 0.5
		var dx = abs(pos.x - jm.global_position.x)
		var dy = pos.y - jm.global_position.y  # có dấu

		var x_tol = max(half.x, 16.0) + MARKER_X_PAD

		var base_y = max(half.y, 10.0)
		var y_up = min(base_y + MARKER_Y_UP_PAD, MARKER_Y_CAP)
		var y_down = min(base_y + MARKER_Y_DOWN_PAD, MARKER_Y_CAP)

		if dx > x_tol:
			continue
		if dy < -y_up:
			continue
		if dy > y_down:
			continue

		var score = dx + abs(dy) * 2.0
		if score < best_score:
			best_score = score
			best = jm

	return best

func _boss_marker() -> JumpMarker2D:
	return _marker_for_pos(obj.global_position)

func _player_marker(p: Node2D) -> JumpMarker2D:
	return _marker_for_pos(p.global_position) if p else null

func _same_platform(player: Node2D) -> bool:
	if player == null:
		return false

	var bm := _boss_marker()
	var pm := _player_marker(player)

	if bm == null and pm == null:
		return true
	if bm == null or pm == null:
		return false

	return bm.get_parent() == pm.get_parent()

func _dijkstra_next(from: JumpMarker2D, to: JumpMarker2D) -> JumpMarker2D:
	if from == null or to == null or from == to:
		return to

	var dist := {from: 0.0}
	var prev := {}
	var open: Array[JumpMarker2D] = [from]

	while not open.is_empty():
		var best_i := 0
		for i in range(1, open.size()):
			if dist.get(open[i], INF) < dist.get(open[best_i], INF):
				best_i = i
		var cur = open.pop_at(best_i)
		if cur == to:
			break

		for nb in cur.connected_markers:
			if nb == null or not nb.is_active:
				continue
			var w = cur.global_position.distance_to(nb.global_position)
			w += (50.0 if not nb.is_safe_spot else 0.0)
			w -= nb.jump_priority * 20.0
			w = max(1.0, w) 

			var nd = dist.get(cur, INF) + w
			if nd < dist.get(nb, INF):
				dist[nb] = nd
				prev[nb] = cur
				if not open.has(nb):
					open.append(nb)

	if not prev.has(to):
		return from.get_best_jump_to_target(to.global_position) if from else null

	var step := to
	while prev.has(step) and prev[step] != from:
		step = prev[step]
	return step
	
func control_move(speed: float, attack_table: Array, _on_reach: Callable, _use_edge_modes: bool) -> void:
	var p = obj.get_player()
	if p == null:
		change_state(fsm.states.idle)
		return

	var same_level = abs(p.global_position.y - obj.global_position.y) <= SAME_LEVEL_THRESHOLD
	var in_range = abs(p.global_position.x - obj.global_position.x) <= obj.attack_range

	if obj.can_attack and same_level and in_range:
		obj.velocity.x = 0.0
		obj.start_attack_cooldown()
		_choose_attack_from_table(attack_table)
		return

	if obj.in_phase2 and obj.state_transition_cooldown <= 0:
		if p.global_position.y < obj.global_position.y - 100:
			var horizontal_distance = abs(p.global_position.x - obj.global_position.x)
			if horizontal_distance <= 200:
				obj.state_transition_cooldown = 1.0  # 1 second cooldown
				change_state(fsm.states.jumpstate)
				return

		if not _same_platform(p) and p.global_position.y > obj.global_position.y:
			var horizontal_distance = abs(p.global_position.x - obj.global_position.x)
			if horizontal_distance <= 300:
				var direction = sign(p.global_position.x - obj.global_position.x)
				if direction == 0:
					direction = 1  
				obj.velocity.x = direction * obj.air_horizontal_speed
				obj.velocity.y = -50  
				obj.state_transition_cooldown = 1.5  
				change_state(fsm.states.fallstate)
				return

	var dx = p.global_position.x - obj.global_position.x
	var dir_x = sign(dx)

	if dir_x == 0:
		dir_x = _last_move_dir_x
		if dir_x == 0:
			dir_x = 1 if not obj.animated_sprite_2d.flip_h else -1
	else:
		_last_move_dir_x = dir_x

	obj.velocity.x = float(dir_x) * speed

func _choose_attack_from_table(attack_table: Array) -> void:
	var r := randf()
	var acc := 0.0
	for item in attack_table:
		if item.size() < 2:
			continue
		var st = item[0]
		var w: float = float(item[1])
		acc += w
		if r <= acc:
			change_state(st)
			return

func control_jump_enter(extra_jump_height: float = 24.0) -> void:
	_has_reached_peak = false
	var p = obj.get_player()
	if p == null:
		change_state(fsm.states.idle)
		return

	if p.global_position.y < obj.global_position.y:
		var jump_direction = sign(p.global_position.x - obj.global_position.x)
		if jump_direction == 0:
			jump_direction = 1

		var jump_height = max(abs(p.global_position.y - obj.global_position.y) + extra_jump_height, 50.0)
		var gravity = _get_gravity_value()
		var vy = -sqrt(2.0 * gravity * jump_height)

		var vx = jump_direction * obj.air_horizontal_speed

		obj.change_direction(jump_direction)
		obj.velocity = Vector2(vx, vy)
	else:
		change_state(fsm.states.surf)
	
func _plan_drop_edge(from: JumpMarker2D, p: Node2D) -> void:
	var half_x := from.platform_size.x * 0.5
	var cx := from.global_position.x
	var left := cx - half_x - DROP_EDGE_OUT
	var right := cx + half_x + DROP_EDGE_OUT

	var dxp := p.global_position.x - obj.global_position.x
	var dir = sign(dxp)

	if abs(dxp) <= DROP_UNDER_X:
		dir = 1 if obj.global_position.x >= cx else -1
	if dir == 0:
		dir = 1

	_drop_x = obj.clamp_x_to_room(right if dir > 0 else left)
	_drop_force_x = _drop_x
	_drop_active = true

func control_jump_update(delta: float, land_state_phase2, land_state_normal) -> void:
	if not _has_reached_peak and obj.velocity.y >= 0.0:
		_has_reached_peak = true

	if _has_reached_peak:
		_try_air_attack(150.0, 100.0, false, 0.3, true   )

	_clamp_position_to_bounds()

	if obj.velocity.y >= 0.0 and _has_reached_peak:
		if obj.is_on_floor():
			if obj.in_phase2:
				change_state(fsm.states.surf)
			else:
				change_state(land_state_normal)
		else:
			change_state(fsm.states.fallstate)

func _get_gravity_value() -> float:
	var g = ProjectSettings.get_setting("physics/2d/default_gravity")
	if typeof(g) == TYPE_FLOAT or typeof(g) == TYPE_INT:
		return float(g)
	return 980.0

func _perform_jump_to_position(target_pos: Vector2, extra_jump_height: float) -> void:
	var start_pos := obj.global_position
	var dx := target_pos.x - start_pos.x
	var g := _get_gravity_value()

	var base_extra = max(extra_jump_height, 10.0)

	var needed_up_height = max(0.0, (start_pos.y - target_pos.y) + base_extra)
	var vy := -sqrt(2.0 * g * max(1.0, needed_up_height))

	var dy := target_pos.y - start_pos.y  
	var disc := vy * vy + 2.0 * g * dy
	if disc < 0.0:
		disc = 0.0
	var t := (-vy + sqrt(disc)) / g
	t = clamp(t, 0.35, 1.2)

	var max_air = max(1.0, obj.air_horizontal_speed)
	var t_need = abs(dx) / max_air
	var iter := 0
	while t < t_need and iter < 6:
		iter += 1
		needed_up_height += 40.0
		vy = -sqrt(2.0 * g * needed_up_height)

		dy = target_pos.y - start_pos.y
		disc = vy * vy + 2.0 * g * dy
		if disc < 0.0:
			disc = 0.0
		t = (-vy + sqrt(disc)) / g
		t = clamp(t, 0.35, 1.2)

	var vx := dx / t
	vx = clamp(vx, -max_air, max_air)

	var dir_x = sign(dx)
	if dir_x == 0:
		dir_x = 1 if not obj.animated_sprite_2d.flip_h else -1

	obj.change_direction(dir_x)
	obj.velocity.x = vx
	obj.velocity.y = vy

func _clamp_position_to_bounds() -> void:
	var lb: Rect2 = obj.level_bounds
	if lb.size.x > 0.0:
		var pos := obj.global_position
		pos.x = clamp(pos.x, lb.position.x, lb.position.x + lb.size.x)
		obj.global_position = pos

	if obj.is_on_ceiling():
		obj.global_position.y += 2.0

func control_fall_update(delta: float) -> void:
	if obj.velocity.y > obj.max_fall_speed:
		obj.velocity.y = obj.max_fall_speed

	if obj.in_phase2:
		_try_air_attack(
			150.0, 120.0,
			true,  
			0.75,
			false  
		)

	_adjust_fall_horizontal_movement()

	if obj.is_on_floor():
		obj.velocity.x = 0.0
		_update_current_jump_marker()
		if obj.in_phase2:
			change_state(fsm.states.surf)
		else:
			change_state(fsm.states.idle)

func _adjust_fall_horizontal_movement() -> void:
	var player = obj.get_player()
	var target_x := obj.global_position.x

	if player:
		if obj.in_phase2 and not obj.jump_markers.is_empty():
			var best_marker = obj.get_best_jump_marker_to_player()
			if best_marker and best_marker.global_position.y > obj.global_position.y:
				target_x = best_marker.global_position.x
			else:
				target_x = player.global_position.x
		else:
			target_x = player.global_position.x

		var lb: Rect2 = obj.level_bounds
		if lb.size.x > 0.0:
			target_x = clamp(target_x, lb.position.x, lb.position.x + lb.size.x)

		var dir_x = sign(target_x - obj.global_position.x)
		obj.velocity.x = dir_x * obj.air_horizontal_speed

func _update_current_jump_marker() -> void:
	var nearest_marker = obj.get_nearest_jump_marker()
	if nearest_marker:
		var distance = obj.global_position.distance_to(nearest_marker.global_position)
		if distance < 50.0:
			obj.current_jump_marker = nearest_marker
		else:
			obj.current_jump_marker = null

func _try_air_attack(max_dist: float, max_vertical_diff: float, require_player_below: bool, chance: float, only_phase2: bool) -> void:
	if only_phase2 and not obj.in_phase2:
		return

	var player = obj.get_player()
	if not player:
		return

	var distance := obj.global_position.distance_to(player.global_position)
	var vertical_diff = abs(obj.global_position.y - player.global_position.y)

	if distance > max_dist or vertical_diff > max_vertical_diff:
		return

	if require_player_below and not (player.global_position.y > obj.global_position.y):
		return

	var player_dir = sign(player.global_position.x - obj.global_position.x)
	var facing_dir := 1 if not obj.animated_sprite_2d.flip_h else -1

	if player_dir == facing_dir and randf() < chance:
		change_state(fsm.states.atk_air)

# ---------------- Roll ----------------
var _roll_elapsed := 0.0
var _roll_total_time := 0.0
var _roll_speed_x := 0.0
var _roll_dir := 1
var _roll_has_invincibility := false

const ROLL_MIN_TIME := 0.20          
const ROLL_MIN_DIST := 4.0
const ROLL_END_MARGIN := 4.0         
const ROLL_BOUND_MARGIN := 8.0
const ROLL_THROUGH_BOUND_RATIO := 0.6
const ROLL_THROUGH_PLAYER_OFFSET := 40.0

func control_roll_enter() -> void:
	_roll_elapsed = 0.0
	_roll_has_invincibility = true
	_play_roll_sfx()

	var sprite := obj.animated_sprite_2d as AnimatedSprite2D
	_play_roll_anim(sprite)

	var player = obj.get_player()
	var has_player := player != null

	var start_x := obj.global_position.x
	var bounds = _get_roll_bounds(ROLL_BOUND_MARGIN)  

	_roll_dir = _pick_roll_dir(player, has_player)    
	var target_x := _pick_roll_target_x(start_x, _roll_dir, player, has_player, bounds)

	var dist = max(abs(target_x - start_x), ROLL_MIN_DIST)
	var base_speed = max(obj.roll_speed, 1.0)
	_roll_total_time = max(dist / base_speed, 0.35)
	_roll_speed_x = dist / _roll_total_time

	obj.change_direction(_roll_dir)
	obj.velocity.x = float(_roll_dir) * _roll_speed_x

	var g := obj.get_gravity().y
	var hop_height = max(8.0, obj.roll_peak_height)
	obj.velocity.y = -sqrt(2.0 * g * hop_height)

	_sync_roll_anim_speed(sprite, _roll_total_time)


func control_roll_update(delta: float) -> void:
	_roll_elapsed += delta

	if _roll_elapsed >= ROLL_MIN_TIME and obj.is_on_floor():
		_finish_roll_to_idle()
		return

	if _roll_elapsed <= _roll_total_time:
		obj.velocity.x = float(_roll_dir) * _roll_speed_x
	else:
		obj.velocity.x = 0.0

	obj.velocity.y += obj.get_gravity().y * delta

	var bounds = _get_roll_bounds(ROLL_END_MARGIN)
	if bounds != null:
		var left = bounds.x
		var right = bounds.y
		var pos := obj.global_position
		var clamped_x = clamp(pos.x, left, right)
		if clamped_x != pos.x:
			pos.x = clamped_x
			obj.global_position = pos
			obj.velocity.x = 0.0


func control_roll_exit() -> void:
	_roll_has_invincibility = false
	obj.velocity.x = 0.0
	_reset_roll_anim_speed()

func has_roll_invincibility() -> bool:
	return _roll_has_invincibility

func _play_roll_sfx() -> void:
	if obj.roll:
		obj.roll.play()

func _play_roll_anim(sprite: AnimatedSprite2D) -> void:
	if sprite == null:
		return
	if sprite.animation != "roll":
		sprite.play("roll")

	var frames := sprite.sprite_frames
	if frames and frames.has_animation("roll"):
		if frames.has_method("set_animation_loop"):
			frames.set_animation_loop("roll", true)

func _sync_roll_anim_speed(sprite: AnimatedSprite2D, duration: float) -> void:
	if sprite == null:
		return
	var frames := sprite.sprite_frames
	if frames == null or not frames.has_animation("roll"):
		return

	var fc := frames.get_frame_count("roll")
	var fps := frames.get_animation_speed("roll")
	if fc <= 0 or fps <= 0.0:
		return

	var anim_len := float(fc) / fps
	sprite.speed_scale = clamp(anim_len / max(0.001, duration), 0.15, 4.0)

func _reset_roll_anim_speed() -> void:
	var sprite := obj.animated_sprite_2d as AnimatedSprite2D
	if sprite:
		sprite.speed_scale = 1.0

func _finish_roll_to_idle() -> void:
	_roll_has_invincibility = false
	obj.velocity.x = 0.0
	_reset_roll_anim_speed()
	change_state(fsm.states.idle)

func _get_roll_bounds(margin: float) -> Variant:
	var lb: Rect2 = obj.level_bounds
	if lb.size.x <= 0.0:
		return null
	return Vector2(lb.position.x + margin, lb.position.x + lb.size.x - margin)

func _pick_roll_dir(player: Node2D, has_player: bool) -> int:
	if not has_player:
		return 1
	return 1 if player.global_position.x < obj.global_position.x else -1

func _pick_roll_target_x(start_x: float, dir: int, player: Node2D, has_player: bool, bounds: Variant) -> float:
	var desired = obj.roll_distance
	var target = start_x + float(dir) * desired

	if bounds != null:
		target = clamp(target, bounds.x, bounds.y)

	if has_player and bounds != null:
		var away_dist = abs(target - start_x)
		if away_dist < desired * ROLL_THROUGH_BOUND_RATIO:
			var through_dir = sign(player.global_position.x - start_x)
			if through_dir == 0:
				through_dir = 1
			_roll_dir = through_dir
			target = player.global_position.x + float(through_dir) * ROLL_THROUGH_PLAYER_OFFSET
			target = clamp(target, bounds.x, bounds.y)

	return target
