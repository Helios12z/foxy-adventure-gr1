extends StaticBody2D

func _ready():
	$CollisionShape2D.disabled = true
	pass

func set_collision(enable: bool):
	$CollisionShape2D.disabled = not enable

func print_collision():
	print(not $CollisionShape2D.disabled)
