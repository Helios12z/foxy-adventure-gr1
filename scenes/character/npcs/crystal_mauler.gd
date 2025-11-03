extends CharacterBody2D


func _on_interactive_area_2d_interacted() -> void:
	Dialogic.start("collect_blade")
	$AnimatedSprite2D.flip_h = true
