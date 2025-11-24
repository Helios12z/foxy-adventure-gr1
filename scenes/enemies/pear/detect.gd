extends EnemyState

var detect_time: float = 1.25

func _enter() -> void:
	obj.velocity.x = 0
	obj.change_animation("detect")
	timer = detect_time

func _update(delta: float) -> void:
	obj.velocity.x = 0

	if update_timer(delta):
		var player := _get_detected_player()

		if player:
			var dist := obj.global_position.distance_to(player.global_position)
			var attack_dist = obj.attack_distance 

			if dist <= attack_dist:
				fsm.change_state(fsm.states.idle_atk)
			else:
				if player.global_position.x < obj.global_position.x:
					obj.direction = -1
				else:
					obj.direction = 1
				fsm.change_state(fsm.states.walk)
		else:
			fsm.change_state(fsm.states.idle)


func _get_detected_player() -> Node2D:
	if obj.detect_front.is_colliding():
		var c = obj.detect_front.get_collider()
		if c is Node2D:
			return c

	if obj.detect_back.is_colliding():
		var c = obj.detect_back.get_collider()
		if c is Node2D:
			return c

	return null
