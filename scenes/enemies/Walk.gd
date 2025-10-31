extends EnemyState

func _enter()-> void: 
	obj.change_animation("walk")

func _update(_delta: float) -> void:
	control_walk()
	
