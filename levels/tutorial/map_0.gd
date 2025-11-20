extends Node

@export var camera_bottom_limit_y: float = INF
@export var show_comic_on_start: bool = false
@export var comic_pages_paths: Array[String] = []
var _comic_shown: bool = false

func get_camera_bottom_limit_y() -> float:
	return camera_bottom_limit_y

func _enter_tree() -> void:
	# Handle portal spawning first
	GameManager.current_stage = self

func _ready() -> void:
	if not GameManager.respawn_at_portal():
		GameManager.respawn_at_checkpoint()
	if show_comic_on_start and comic_pages_paths.size() > 0 and not _comic_shown:
		_show_map_story()

func _show_map_story() -> void:
	var viewer_scene: PackedScene = preload("res://scenes/ui/comic_viewer.tscn")
	var viewer := viewer_scene.instantiate()
	# nạp các trang theo đường dẫn cấu hình
	if "pages" in viewer:
		var arr: Array[Texture2D] = []
		for p in comic_pages_paths:
			var tex := load(p)
			if tex:
				arr.append(tex)
		viewer.pages = arr
	add_child(viewer)
	_comic_shown = true
