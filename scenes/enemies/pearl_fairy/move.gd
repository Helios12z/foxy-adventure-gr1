extends EnemyState

@export var keep_distance: float = 180.0
@export var attack_interval: float = 4.8

var _attack_timer: float = 0.0

func _enter() -> void:
	obj.change_animation("move")
	if obj.attack_immediately_next_move:
		_attack_timer = 0.0
	else:
		_attack_timer = attack_interval
	obj.attack_immediately_next_move = false
	if obj.has_node("Direction/MoveMarker2D"):
		var m: Marker2D = obj.get_node("Direction/MoveMarker2D")
		m.global_position = obj.global_position

func _update(delta: float) -> void:
	if obj.found_player == null:
		change_state(fsm.states.idle)
		return
	var p = obj.found_player.global_position
	var to_p = p - obj.global_position
	var dist = to_p.length()
	var dir := Vector2.ZERO
	if dist > keep_distance + 12.0:
		dir = to_p.normalized()
	elif dist < keep_distance - 12.0:
		dir = (-to_p).normalized()
	else:
		dir = Vector2.ZERO
	obj.velocity = dir * obj.movement_speed
	var desired := 1 if (p.x - obj.global_position.x) > 0.0 else -1
	if desired != obj.direction:
		obj.change_direction(desired)
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		if obj.attack_cooldown_timer <= 0.0:
			_attack_timer = attack_interval
			change_state(fsm.states.attack)
		else:
			_attack_timer = obj.attack_cooldown_timer
