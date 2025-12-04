extends Area2D

# Script tổng quát để phát âm thanh khi player vào vùng
# Sử dụng AudioStreamPlayer (không dùng AudioStreamPlayer2D)

@onready var audio_player = $AudioStreamPlayer

func _ready() -> void:
	# Set collision mask để chỉ detect Player (layer 2)
	collision_layer = 0
	collision_mask = 2  # Player layer
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	print("AudioZone ready, audio_player: ", audio_player)
	if audio_player:
		print("Audio stream: ", audio_player.stream)

func _on_body_entered(body: Node) -> void:
	print("Body entered: ", body.name, " | Groups: ", body.get_groups())
	# Kiểm tra cả tên và group
	if body.name == "Player" or body.is_in_group("Player") or body.is_in_group("player"):
		print("Player entered audio zone!")
		if audio_player:
			print("Playing audio...")
			audio_player.play()
		else:
			print("ERROR: audio_player is null!")

func _on_body_exited(body: Node) -> void:
	print("Body exited: ", body.name)
	if body.name == "Player" or body.is_in_group("Player") or body.is_in_group("player"):
		print("Player exited audio zone!")
		if audio_player:
			audio_player.stop()
