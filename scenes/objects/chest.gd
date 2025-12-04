extends Node2D

@export var requires_key: bool = true
@export var reward_scenes: Array[PackedScene] = []
@export var reward_counts: Array[int] = []
@export var spawn_height: float = 8.0
@export var scatter_radius: float = 24.0

var is_opened: bool = false
var is_interacted: bool = false

@onready var interactive_area: InteractiveArea2D = $InteractiveArea2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var chest_open: AudioStreamPlayer2D = $ChestOpen

func _ready() -> void:
	if interactive_area:
		interactive_area.interacted.connect(_on_interacted)
		interactive_area.interaction_available.connect(_on_interaction_available)
		interactive_area.interaction_unavailable.connect(_on_interaction_unavailable)

	_sync_counts_array()
	
	is_opened = GameManager.is_chest_opened()

	if is_opened:
		animated_sprite.play("open")
		_disable_chest_collision()
	else:
		animated_sprite.play("close")

func _on_interaction_available() -> void:
	is_interacted = true

func _on_interaction_unavailable() -> void:
	is_interacted = false

func _on_interacted() -> void:
	# CHỐT CHẶN QUAN TRỌNG: chỉ xử lý nếu player đang trong vùng chest này
	if not is_interacted:
		return
	attempt_open_chest()

func _sync_counts_array() -> void:
	while reward_counts.size() < reward_scenes.size():
		reward_counts.append(1)
	if reward_counts.size() > reward_scenes.size():
		reward_counts.resize(reward_scenes.size())

func attempt_open_chest() -> void:
	if is_opened:
		return

	if requires_key and not GameManager.inventory_system.has_key():
		# TODO: sound "locked", popup "Cần chìa"
		return

	open_chest()

func open_chest() -> void:
	if is_opened:
		return

	chest_open.play()
	is_opened = true

	if requires_key:
		GameManager.inventory_system.use_key()

	animated_sprite.play("open")
	await animated_sprite.animation_finished

	_spawn_rewards()
	_disable_chest_collision()

	GameManager.mark_chest_opened()

func _disable_chest_collision() -> void:
	var shape := find_child("CollisionShape2D", true, false)
	if shape is CollisionShape2D:
		shape.disabled = true

func _spawn_rewards() -> void:
	var world := get_tree().current_scene
	randomize()

	for i in reward_scenes.size():
		var scene: PackedScene = reward_scenes[i]
		if scene == null:
			continue

		var count: int 
		if i < reward_counts.size(): count = reward_counts[i]
		else: count = 1
		if count <= 0:
			continue

		for j in count:
			var inst := scene.instantiate()
			var base_pos := global_position + Vector2(0, -spawn_height)
			var offset := Vector2(
				randf_range(-scatter_radius, scatter_radius),
				randf_range(-scatter_radius, 0.0)
			)
			inst.global_position = base_pos + offset
			world.add_child(inst)
