extends EnemyState

enum { HOVER, DASH, IMPACT }
var phase := HOVER
var hover_timer := 0.0
var hover_y := 0.0
var start_x := 0.0

func _enter()->void:
	obj.change_animation("atk3_fly_and_hit")

	start_x = obj._atk3_liftoff_x
	hover_y = obj._atk3_drop_target.y - obj.atk3_fly_height

	obj.global_position = Vector2(start_x, hover_y)

	phase = HOVER
	hover_timer = obj.atk3_hover_time

func _update(d: float)->void:
	match phase:
		HOVER:
			obj.global_position = Vector2(start_x, hover_y)
			hover_timer -= d
			if hover_timer <= 0.0:
				phase = DASH

		DASH:
			var target = obj._atk3_drop_target
			var to_target = target - obj.global_position
			var dist = to_target.length()

			if dist <= 2.0:
				obj.global_position = target
				_do_impact()
				return

			var dir = to_target / max(dist, 0.001)
			var step = dir * obj.atk3_dash_speed * d

			if step.length() >= dist:
				obj.global_position = target
				_do_impact()
			else:
				obj.global_position += step

		IMPACT:
			change_state(fsm.states.idle) 
			return

func _do_impact() -> void:
	obj._snap_to_ground() 
	obj._end_fly_mode()
	obj._proximity_enabled = true  
	phase = IMPACT
