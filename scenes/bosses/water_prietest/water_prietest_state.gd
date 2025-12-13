extends EnemyState
class_name WaterPrietestState

const SAME_LEVEL_THRESHOLD := 10.0
const DROP_UNDER_X := 12.0
const DROP_EDGE_OUT := 12.0
const NAV_EPS_X := 6.0

var _jump_target_x: float = 0.0
var _jump_dir_x: int = 0
var _has_reached_peak: bool = false
var _drop_active := false
var _drop_x := 0.0
var _drop_force_x := 0.0

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
	for m in _all_markers():
		var jm := m as JumpMarker2D
		if jm == null or not jm.is_active:
			continue

		var half := jm.platform_size * 0.5
		var dx = abs(pos.x - jm.global_position.x)

		var dy = abs(pos.y - jm.global_position.y)
		var y_tol = max(half.y, 10.0) + 12.0   

		if dx <= half.x and dy <= y_tol:
			var score = dx + dy * 2.0
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
			var w = cur.global_position.distance_to(nb.global_position) \
				- nb.jump_priority * 20.0 \
				+ (50.0 if not nb.is_safe_spot else 0.0)

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

	if obj.in_phase2 and not _same_platform(p):
		var bm := _boss_marker()
		var pm := _player_marker(p)

		if bm != null and pm == null:
			obj.force_phase2_ground_jump = true

		change_state(fsm.states.jumpstate)
		return

	var same_level = abs(p.global_position.y - obj.global_position.y) <= SAME_LEVEL_THRESHOLD
	var in_range = abs(p.global_position.x - obj.global_position.x) <= obj.attack_range

	if obj.can_attack and same_level and in_range:
		obj.velocity.x = 0.0
		obj.start_attack_cooldown()
		_choose_attack_from_table(attack_table)
		return

	obj.velocity.x = sign(p.global_position.x - obj.global_position.x) * speed

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

	if obj.in_phase2 and obj.force_phase2_ground_jump:
		var target := obj.global_position
		target.x = obj.clamp_x_to_room(_drop_force_x if _drop_force_x != 0.0 else target.x)
		if obj.rect_platform:
			target.y = obj.rect_platform.global_position.y - 16.0
		_perform_jump_to_position(target, 0.0)
		obj.force_phase2_ground_jump = false
		_drop_force_x = 0.0
		return

	var from := _marker_for_pos(obj.global_position)
	var to := _marker_for_pos(p.global_position) if p else null
	var next := _dijkstra_next(from, to) if (from and to) else (to if to else null)

	if next:
		_perform_jump_to_position(next.global_position, 0.0)
		return

	_fallback_jump_to_player(p, extra_jump_height)
	
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
		_try_air_attack(
			150.0, 100.0,
			false, 
			0.3,
			true   
		)

	_clamp_position_to_bounds()

	if obj.velocity.y >= 0.0 and _has_reached_peak:
		if obj.is_on_floor():
			if obj.in_phase2 and land_state_phase2:
				change_state(land_state_phase2)
			else:
				change_state(land_state_normal)
		else:
			change_state(fsm.states.fallstate)

func _fallback_jump_to_player(player: Node2D, extra_jump_height: float) -> void:
	var target_pos := obj.global_position

	if player:
		target_pos = player.global_position
		var lb: Rect2 = obj.level_bounds
		if lb.size.x > 0.0:
			target_pos.x = clamp(target_pos.x, lb.position.x, lb.position.x + lb.size.x)

	_jump_target_x = target_pos.x
	_perform_jump_to_position(target_pos, extra_jump_height)

func _get_gravity_value() -> float:
	var g = ProjectSettings.get_setting("physics/2d/default_gravity")
	if typeof(g) == TYPE_FLOAT or typeof(g) == TYPE_INT:
		return float(g)
	return 980.0

func _perform_jump_to_position(target_pos: Vector2, extra_jump_height: float) -> void:
	var start_pos := obj.global_position
	var dx := target_pos.x - start_pos.x

	var g := _get_gravity_value()

	var needed_up_height = max(0.0, start_pos.y - target_pos.y + extra_jump_height)
	var initial_vy := -sqrt(2.0 * g * needed_up_height)

	var time_to_peak := -initial_vy / g
	var total_time := time_to_peak * 2.0
	total_time = clamp(total_time, 0.35, 1.2)

	var vx := dx / total_time
	var max_air_speed = obj.air_horizontal_speed
	if abs(vx) > max_air_speed:
		vx = sign(vx) * max_air_speed

	_jump_dir_x = sign(vx)
	if _jump_dir_x == 0:
		_jump_dir_x = 1 if dx >= 0.0 else -1

	obj.change_direction(_jump_dir_x)
	obj.velocity.x = vx
	obj.velocity.y = initial_vy


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

var _roll_start_x: float = 0.0
var _roll_start_y: float = 0.0
var _roll_target_x: float = 0.0
var _roll_total_time: float = 0.0
var _roll_elapsed: float = 0.0
var _roll_speed_x: float = 0.0
var _roll_direction: int = 1
var _roll_has_invincibility: bool = false

const ROLL_EXTRA_HEIGHT_MULT := 1.2
const ROLL_THROUGH_BOUND_RATIO := 0.6
const ROLL_THROUGH_PLAYER_OFFSET := 40.0

func control_roll_enter() -> void:
	var sprite: AnimatedSprite2D = obj.animated_sprite_2d
	if sprite:
		sprite.speed_scale = 1.0

	_roll_has_invincibility = true

	if obj.roll:
		obj.roll.play()

	_roll_start_x = obj.global_position.x
	_roll_start_y = obj.global_position.y
	_roll_elapsed = 0.0

	var player = obj.get_player()
	var has_player := player != null

	if has_player:
		# giữ nguyên logic cũ của bạn
		if player.global_position.x < obj.global_position.x:
			_roll_direction = 1
		else:
			_roll_direction = -1
	else:
		_roll_direction = 1

	var lb: Rect2 = obj.level_bounds
	var margin := 8.0
	var has_bounds := lb.size.x > 0.0

	var left := 0.0
	var right := 0.0
	if has_bounds:
		left = lb.position.x + margin
		right = lb.position.x + lb.size.x - margin

	var desired_distance = obj.roll_distance
	var away_target_x = _roll_start_x + float(_roll_direction) * desired_distance

	if has_bounds:
		away_target_x = clamp(away_target_x, left, right)

	var away_distance = abs(away_target_x - _roll_start_x)

	var use_roll_through := false
	if has_player and has_bounds:
		if away_distance < desired_distance * ROLL_THROUGH_BOUND_RATIO:
			use_roll_through = true

	var final_target_x: float
	if use_roll_through:
		_roll_direction = sign(player.global_position.x - _roll_start_x)
		if _roll_direction == 0:
			_roll_direction = 1

		final_target_x = player.global_position.x + float(_roll_direction) * ROLL_THROUGH_PLAYER_OFFSET
		if has_bounds:
			final_target_x = clamp(final_target_x, left, right)
	else:
		final_target_x = away_target_x

	_roll_target_x = final_target_x

	var distance = abs(_roll_target_x - _roll_start_x)
	if distance < 4.0:
		distance = 4.0

	var base_speed = max(obj.roll_speed, 1.0)
	_roll_total_time = distance / base_speed
	_roll_total_time = max(_roll_total_time, 0.35)

	# ---- fit tốc độ di chuyển để đúng total_time + đúng target ----
	_roll_speed_x = distance / _roll_total_time
	obj.velocity.x = float(_roll_direction) * _roll_speed_x

	# ---- parabolic hop (nhẹ) ----
	var g := obj.get_gravity().y
	var vy0 := -0.5 * g * _roll_total_time
	obj.velocity.y = vy0

	obj.change_direction(_roll_direction)

	if sprite:
		# đảm bảo đang play roll (nếu state enter chưa play)
		if sprite.animation != "roll":
			sprite.play("roll")

		var frames := sprite.sprite_frames
		if frames and frames.has_animation("roll"):
			var fc := frames.get_frame_count("roll")
			var fps := frames.get_animation_speed("roll") # frames/sec
			if fc > 0 and fps > 0.0:
				var anim_len := float(fc) / fps
				# duration thực = anim_len / speed_scale  => speed_scale = anim_len / total_time
				sprite.speed_scale = clamp(anim_len / _roll_total_time, 0.1, 4.0)


func control_roll_update(delta: float) -> void:
	_roll_elapsed += delta

	# ĐỪNG update_facing khi roll (dễ flip giật hướng)
	# obj._update_facing()

	obj.velocity.x = float(_roll_direction) * _roll_speed_x
	obj.velocity.y += obj.get_gravity().y * delta

	var lb: Rect2 = obj.level_bounds
	if lb.size.x > 0.0:
		var margin := 4.0
		var left := lb.position.x + margin
		var right := lb.position.x + lb.size.x - margin
		var pos := obj.global_position
		pos.x = clamp(pos.x, left, right)
		obj.global_position = pos

	var done_time := _roll_elapsed >= _roll_total_time
	var landed := obj.is_on_floor() and _roll_elapsed > 0.05

	if done_time and landed:
		_roll_has_invincibility = false
		obj.velocity.x = 0.0

		# reset speed_scale cho chắc
		var sprite: AnimatedSprite2D = obj.animated_sprite_2d
		if sprite:
			sprite.speed_scale = 1.0

		change_state(fsm.states.idle)

func control_roll_exit() -> void:
	_roll_has_invincibility = false
	obj.velocity.x = 0.0
	var sprite: AnimatedSprite2D = obj.animated_sprite_2d
	if sprite:
		sprite.speed_scale = 1.0


func has_roll_invincibility() -> bool:
	return _roll_has_invincibility
	
func _pick_drop_x_to_rect(player: Node2D) -> float:
	var x := obj.global_position.x

	if obj.in_phase2 and not obj.jump_markers.is_empty():
		var m = obj.get_best_jump_marker_to_player()
		# FIX: chỉ dùng marker nếu nó nằm THẤP hơn boss (đường xuống)
		if m and m.global_position.y > obj.global_position.y:
			x = m.global_position.x
		elif player:
			x = player.global_position.x
	elif player:
		x = player.global_position.x

	return obj.clamp_x_to_room(x)
	
func _drop_to_rect_now(_dy: float) -> void:
	obj.force_phase2_ground_jump = true
	change_state(fsm.states.jumpstate)
