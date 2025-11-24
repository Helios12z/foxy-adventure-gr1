extends EnemyState

func _enter() -> void:
	print("enter dead state")
	owner.hit_area_2d.monitoring = false
	owner.hit_area_2d.monitorable = false
	owner.hurt_area_2d.monitoring = false
	owner.hurt_area_2d.monitorable = false
	obj.queue_free()
