extends WarlordTurtleState

func _enter() -> void:
	obj.velocity.x=0
	timer = 1.0

func _update(d: float) -> void:
	if update_timer(d):
		if obj.water_room_gem_scene != null:
			var gem = obj.water_room_gem_scene.instantiate() as Node2D
			gem.global_position = obj.global_position
			obj.get_parent().add_child(gem)
		obj.queue_free()
