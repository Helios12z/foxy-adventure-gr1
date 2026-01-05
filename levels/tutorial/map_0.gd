extends Node

@export var camera_bottom_limit_y: float = INF
@export var show_comic_on_start: bool = true
@export var comic_pages_paths: Array[String] = []
var _comic_shown: bool = false

func get_camera_bottom_limit_y() -> float:
	return camera_bottom_limit_y

func _enter_tree() -> void:
	# Handle portal spawning first
	GameManager.current_stage = self

func _ready() -> void:
	# Immediately stop ambient music if we are going to show the comic
	if show_comic_on_start and comic_pages_paths.size() > 0 and not _comic_shown:
		_set_ambient_music_playing(false)
		
	# Only handle portal/door spawning, NOT auto-respawn
	# Defeat screen will handle respawning now
	GameManager.respawn_at_portal()
	
	if show_comic_on_start and comic_pages_paths.size() > 0 and not _comic_shown:
		_show_map_story()

func _show_map_story() -> void:
	var viewer_scene: PackedScene = load("res://scenes/ui/comic_viewer.tscn")
	var viewer := viewer_scene.instantiate()
	# nạp các trang theo đường dẫn cấu hình
	if "pages" in viewer:
		var arr: Array[Texture2D] = []
		for p in comic_pages_paths:
			var tex := load(p)
			if tex:
				arr.append(tex)
		viewer.pages = arr
	
	# Configure auto-play for Map 0
	var music = load("res://asset/sounds/start_game_music.ogg")
	var timestamps = [7.0, 14.0, 20.0, 29.0, 33.5, 37.0, 46.0]
	viewer.setup_auto_play(music, timestamps)
	
	viewer.finished.connect(_on_comic_finished)

	add_child(viewer)
	_comic_shown = true

func _on_comic_finished() -> void:
	_set_ambient_music_playing(true)

func _set_ambient_music_playing(playing: bool) -> void:
	var music_nodes = ["Music2", "Music3"]
	for node_name in music_nodes:
		if has_node(node_name):
			var player = get_node(node_name)
			if player is AudioStreamPlayer:
				if playing:
					if not player.playing:
						player.play()
				else:
					player.stop()
