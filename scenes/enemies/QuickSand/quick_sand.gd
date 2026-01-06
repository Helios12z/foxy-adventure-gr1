extends Area2D

## QuickSand - Giảm 50% movement speed của player khi đi vào

@export var speed_multiplier: float = 0.5  # Giảm còn 50% speed

var player_ref: Player = null
var original_speed: float = 0.0

@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

func _ready() -> void:
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_ref = body as Player
		# Lưu speed gốc
		original_speed = player_ref._base_movement_speed
		# Gọi hàm enter_quicksand của player
		player_ref.enter_quicksand(speed_multiplier)
		
		# Phát âm thanh
		if audio_player and not audio_player.playing:
			audio_player.play()

func _on_body_exited(body: Node2D) -> void:
	if body is Player and player_ref != null:
		# Gọi hàm exit_quicksand của player
		player_ref.exit_quicksand(original_speed)
		player_ref = null
		original_speed = 0.0
		
		# Dừng âm thanh
		if audio_player:
			audio_player.stop()
