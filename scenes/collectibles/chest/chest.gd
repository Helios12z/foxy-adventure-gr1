extends InteractiveArea2D

@export var coin_reward: int = 5
@export var coin_scene: PackedScene   # Coin.tscn (script Coin.gd đã nâng cấp)

var is_opened: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	interacted.connect(_on_interacted)
	animated_sprite.play("close")


func _on_interacted() -> void:
	attempt_open_chest()


func attempt_open_chest() -> void:
	if is_opened:
		return

	if GameManager.inventory_system.has_key():
		open_chest()


func open_chest() -> void:
	if is_opened:
		return

	is_opened = true

	# dùng 1 key
	GameManager.inventory_system.use_key()

	# chạy animation mở
	animated_sprite.play("open")
	await animated_sprite.animation_finished

	# spawn coin theo quỹ đạo
	spawn_coins(coin_reward)

	print("Chest opened! Spawned ", coin_reward, " coins!")
	
func spawn_coins(amount: int) -> void:
	for i in amount:
		var coin := coin_scene.instantiate()
		get_parent().add_child(coin)

		# vị trí xuất phát = chest
		coin.global_position = global_position

		# chọn vị trí đáp xuống (random nhẹ)
		var landing_offset := Vector2(
			randf_range(-60, 60),
			randf_range(120, 180)
		)

		var landing_pos := global_position + landing_offset

		# coin bay theo đường cong tới landing_pos
		coin.fly_to(landing_pos)
