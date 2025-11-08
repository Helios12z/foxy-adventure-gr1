extends EnemyState

var t := 0.0
var rise_done := false
var vy := 0.0

func _enter()->void:
	print("into atk3_windup")
	obj.change_animation("atk3_windup")
	timer = obj.atk3_windup_time
	obj.play_attack_effect(4, timer)
	obj._lock_drop_target_at_player()
	t = 0.0
	rise_done = false
	vy = 0.0
	obj._begin_fly_mode()

func _update(d: float)->void:
	t += d
	
	obj.global_position.x = obj._atk3_liftoff_x

	var target_y = obj._atk3_drop_target.y - obj.atk3_fly_height

	if not rise_done:
		var dy = target_y - obj.global_position.y
		var dist = abs(dy)
		var dir = sign(dy)
		var target_speed = obj.atk3_rise_speed * dir

		if dist < obj.atk3_rise_decel_dist:
			var k = clamp(dist / obj.atk3_rise_decel_dist, 0.15, 1.0)
			target_speed *= k

		if vy < target_speed:
			vy = min(vy + obj.atk3_rise_accel * d, target_speed)
		elif vy > target_speed:
			vy = max(vy - obj.atk3_rise_accel * d, target_speed)

		obj.global_position.y += vy * d

		if abs(obj.global_position.y - target_y) <= 2.0:
			obj.global_position.y = target_y
			rise_done = true
			vy = 0.0

	if update_timer(d):
		obj._disable_attack_effect()
		change_state(fsm.states.atk3_fly_and_hit)
