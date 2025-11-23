extends EnemyState

func _enter() -> void:
	owner.water.visible = true
	owner.tornado.visible = true

	owner.tornado.frame = 0
	owner.tornado.play("default")

	owner.hit_area_2d.monitoring = true
	owner.hit_area_2d.monitorable = true
