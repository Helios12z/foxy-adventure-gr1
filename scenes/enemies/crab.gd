extends CharacterBody2D

@export var speed: float = 60.0
var direction := Vector2.RIGHT

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta):
	velocity = direction * speed
	move_and_slide()

	# Animation
	if velocity.x != 0:
		anim.play("walk")
		anim.flip_h = velocity.x < 0
	else:
		anim.play("idle")
