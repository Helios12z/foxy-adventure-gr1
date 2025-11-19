extends KingCrabState

var roll_dir: float = 1.0
var target_x: float
var roll_time: float = 0.0
var roll_speed: float = 0.0

var braking := false          
const EPS := 8.0              

func _enter() -> void:
	obj.change_animation("atk2_roll")

	roll_dir = sign(obj.queued_roll_dir_x)

	roll_speed = obj.movement_speed * obj.roll_speed_mult

	roll_time = 0.0
	braking = false

	if obj.hit_area_2d:
		obj.hit_area_2d.set_deferred("monitoring", true)
		var shape = obj.hit_area_2d.get_node_or_null("CollisionShape2D")
		if shape:
			shape.set_deferred("disabled", false)

		if not obj.hit_area_2d.area_entered.is_connected(_on_roll_hit_area):
			obj.hit_area_2d.area_entered.connect(_on_roll_hit_area)

func _update(d: float) -> void:
	roll_time += d

	if not braking:
		# lăn nhanh
		obj.velocity.x = roll_dir * roll_speed

		if obj.found_player:
			var side_now = sign(obj.found_player.global_position.x - obj.global_position.x)
			if side_now != 0.0 and side_now != roll_dir:
				braking = true

		var near_target := absf(obj.global_position.x - target_x) <= 10.0
		if obj.is_touch_wall() or near_target:
			braking = true
			
		if obj.is_can_fall(): 
			braking = true 

		if roll_time >= obj.roll_max_time:
			braking = true
	else:
		obj.velocity.x = move_toward(obj.velocity.x, 0.0, obj.roll_brake * d)
		if absf(obj.velocity.x) <= EPS:
			obj.velocity.x = 0.0
			change_state(fsm.states.atk2_stop)

func _on_roll_hit_area(a: Area2D) -> void:
	if fsm.current_state!=fsm.states.atk2_roll:
		return 
	obj.velocity.x = 0.0
	change_state(fsm.states.atk2_stop)
	
func _exit()->void:
	toggle_next_attack()
