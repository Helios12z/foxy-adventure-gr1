extends RigidBody2D

func _on_hit_area_2d_hitted(_area: Variant) -> void:
	queue_free()

func _on_body_entered(body):
	if body.name == "TileMapLayer":
		queue_free()
