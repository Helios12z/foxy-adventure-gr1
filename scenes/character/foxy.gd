extends CharacterBody2D
var gravity = 150.0

func _process(delta: float) -> void:
	velocity.y += gravity * delta
	move_and_slide()
