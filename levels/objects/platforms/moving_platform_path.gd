extends Path2D

@export var speed: float = 100.0          # tốc độ di chuyển
@export var loop: bool = true             # có lặp lại đường path hay không

func _ready():
	var follow = $PathFollow2D
	if loop:
		follow.loop = true

func _physics_process(delta):
	$PathFollow2D.progress += speed * delta
