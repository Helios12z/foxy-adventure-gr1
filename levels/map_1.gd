extends Node


@export var camera_bottom_limit_y: float = INF
@export var show_tutorial_on_start: bool = true

@onready var player = $Player

var _tutorial_shown: bool = false

func get_camera_bottom_limit_y() -> float:
	return camera_bottom_limit_y

func _enter_tree() -> void:
	# Handle portal spawning first
	GameManager.current_stage = self

func _ready() -> void:
	# Only handle portal/door spawning, NOT auto-respawn
	# Defeat screen will handle respawning now
	# Handle portal/door spawning first
	GameManager.is_scene_boss = false
	if not GameManager.respawn_at_portal():
		# If no portal target, try to respawn at checkpoint
		print("[Map1] No portal target, attempting checkpoint respawn...")
		GameManager.respawn_at_checkpoint()
	
	# Hiển thị tutorial tự động khi vào map 1 lần đầu
	if show_tutorial_on_start and not _tutorial_shown:
		_show_first_tutorial()

	# Ensure all AudioStreamPlayers in the scene loop (Fix for Web/itch.io)
	for child in get_children():
		if child is AudioStreamPlayer or child is AudioStreamPlayer2D:
			# Check if it has a stream and (optional but safe) bus is Music or SFX/Ambient
			if child.stream:
				# Force connection to ensure loop
				if not child.finished.is_connected(child.play):
					child.finished.connect(child.play)
				# Ensure it's playing if it was set to autoplay but stopped or failed
				if child.autoplay and not child.playing:
					child.play()

func _show_first_tutorial() -> void:
	_tutorial_shown = true
	
	# Đợi loading screen biến mất hoàn toàn và scene sẵn sàng
	await get_tree().create_timer(2.2, true, false, true).timeout
	
	var tutorial_manager = get_node_or_null("/root/TutorialManager")
	if tutorial_manager == null:
		print("TutorialManager not found!")
		return
	
	# Tìm UI layer để add popup
	var ui_layer = get_node_or_null("UI")
	if ui_layer == null:
		print("UI layer not found!")
		return
	
	# Tạo popup và hiển thị tutorial đầu tiên của Map 1 (index 2 - Climb Tutorial)
	var popup_tutorials = load("res://levels/tutorial/signpost_details/tutorial_popup1.tscn").instantiate()
	ui_layer.add_child(popup_tutorials)
	
	# Hiển thị tutorial từ đầu (index 0)
	tutorial_manager.show_tutorial(0, popup_tutorials)

func _process(delta: float) -> void:
	pass
