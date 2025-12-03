extends Area2D

@onready var rain = $RainParticles
@onready var cam = get_viewport().get_camera_2d()

func _process(delta):
	if rain.emitting:
		# chỉ khi đang mưa mới cập nhật theo camera (không phí)
		rain.global_position = cam.global_position

func _on_body_entered(body):
	if body.name == "Player":
		rain.emitting = true
	print("Player vào vùng mưa!")
	print("Emitting:", rain.emitting)

func _on_body_exited(body):
	if body.name == "Player":
		rain.emitting = false
