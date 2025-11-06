extends EnemyState

func _enter()->void:
	obj.change_animation("atk_1")
	
func _update(delta: float)->void:
	pass 
