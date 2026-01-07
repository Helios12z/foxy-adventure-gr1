extends Node

# Loading Manager - Autoload script for managing loading screen content
var loading_config: Dictionary
var scene_to_content_mapping: Dictionary

func _ready():
	_load_config()
	_build_scene_mapping()

func _load_config():
	var config_file = FileAccess.open("res://asset/ui/loading/loading_content/loading_config.json", FileAccess.READ)
	if config_file:
		var json_string = config_file.get_as_text()
		var json = JSON.new()
		var parse_result = json.parse(json_string)

		if parse_result == OK:
			loading_config = json.data
			print("Loading config loaded successfully")
		else:
			push_error("Failed to parse loading config: " + json.get_error_message())
	else:
		push_error("Failed to open loading config file")
		# Create default config if file doesn't exist
		loading_config = {
			"default_content": {
				"images": [],
				"tips": ["Loading..."],
				"area_name": "Unknown Lands",
				"loading_duration": 2.0
			},
			"area_content": {}
		}

func _build_scene_mapping():
	# Map scene paths to content based on their names and UIDs
	scene_to_content_mapping = {
		# Tutorial/Map0
		"res://levels/tutorial/map0.tscn": "tutorial",

		# King Crab level
		"uid://x5qrj66qebnm": "king_crab",  # level_king_crab.tscn
		"res://levels/boss_levels/king_crab/level_king_crab.tscn": "king_crab",

		# Map 1 - Forest area
		"uid://65dl3olpohwm": "island",  # map1.tscn
		"res://levels/map1.tscn": "island",

		# Map 2
		"uid://dq7eu5p47t8gv": "dark_forest",  # map_2.tscn
		"res://levels/map_2.tscn": "dark_forest",

		# War Lord Turtle
		"res://levels/boss_levels/war_lord_turtle/level_war_lord_turtle.tscn": "war_lord_turtle",
		"uid://k0emccpu8xrk": "war_lord_turtle",

		# Map 3 - Water Palace
		"uid://du7hahnxorxmd": "map_3",
		"res://levels/map_3.tscn": "map_3",

		# Water Priestess
		"uid://kv02hvhfsd8k": "water_priestess",
		"res://levels/boss_levels/water_prietress/level_water_prietess.tscn": "water_priestess",

		# Boss 3 - Water Goddess
		"uid://bhwnd0dvsqev8": "boss3_water_goddess",
		"res://scenes/test_scenes/test_boss3.tscn": "boss3_water_goddess"
	}

func get_content_for_transition(from_scene: String, to_scene: String) -> Dictionary:
	# Try to get content based on transition
	var transition_key = _get_transition_key(from_scene, to_scene)

	if transition_key and loading_config.area_content.has(transition_key):
		var transition_content = loading_config.area_content[transition_key]

		# Process the content to get actual image paths
		var processed_content = transition_content.duplicate()
		processed_content["images"] = _get_images_for_content(transition_key)
		processed_content["content_key"] = transition_key  # Add content_key for preloaded images

		return processed_content

	# Fallback to destination-based loading if no specific transition found
	return get_content_for_scene(to_scene)

func get_content_for_scene(scene_path: String) -> Dictionary:
	# Try to get area content based on scene path or UID
	var content_key = _get_content_key_for_scene(scene_path)

	if content_key and loading_config.area_content.has(content_key):
		var area_content = loading_config.area_content[content_key]

		# Process the content to get actual image paths
		var processed_content = area_content.duplicate()
		processed_content.images = _get_images_for_content(content_key)
		processed_content["content_key"] = content_key  # Add content_key for preloaded images

		return processed_content

	# Return default content if no specific content found
	var default_content = loading_config.default_content.duplicate()
	default_content["images"] = _get_default_images()
	default_content["content_key"] = "island"  # Default to island for preloaded images
	return default_content

func _get_transition_key(from_scene: String, to_scene: String) -> String:
	# Map specific transitions to content keys
	var transition_map = {
		# Map0 → Map1: Show Island loading
		"res://levels/tutorial/map0.tscn→res://levels/map1.tscn": "island",

		# Map1 → King Crab: Show King Crab loading
		"res://levels/map1.tscn→res://levels/boss_levels/king_crab/level_king_crab.tscn": "king_crab",

		# King Crab → Map2: Show Forest loading
		"res://levels/boss_levels/king_crab/level_king_crab.tscn→res://levels/map_2.tscn": "dark_forest",

		# Map2 → War Lord Turtle: Show War Lord Turtle loading
		"res://levels/map_2.tscn→res://levels/boss_levels/war_lord_turtle/level_war_lord_turtle.tscn": "war_lord_turtle",

		# War Lord Turtle → Map3: Show Water Palace loading
		"res://levels/boss_levels/war_lord_turtle/level_war_lord_turtle.tscn→res://levels/map_3.tscn": "map_3",

		# Map3 → Water Priestess: Show Water Priestess loading
		"res://levels/map_3.tscn→res://levels/boss_levels/water_prietress/level_water_prietess.tscn": "water_priestess",

		# Water Priestess → Boss3: Show Water Goddess loading
		"res://levels/boss_levels/water_prietress/level_water_prietess.tscn→res://scenes/test_scenes/test_boss3.tscn": "boss3_water_goddess",

		# Map3 → Boss3: Direct to Water Goddess
		"res://levels/map_3.tscn→res://scenes/test_scenes/test_boss3.tscn": "boss3_water_goddess"
	}

	var transition_key = from_scene + "→" + to_scene
	if transition_map.has(transition_key):
		return transition_map[transition_key]

	return ""

func _get_content_key_for_scene(scene_path: String) -> String:
	# Try direct mapping first
	if scene_to_content_mapping.has(scene_path):
		return scene_to_content_mapping[scene_path]

	# Try to extract UID from path if it contains one
	if "uid://" in scene_path:
		var uid_match = RegEx.new()
		uid_match.compile(r"uid://[a-zA-Z0-9]+")
		var result = uid_match.search(scene_path)
		if result:
			var uid = result.get_string()
			if scene_to_content_mapping.has(uid):
				return scene_to_content_mapping[uid]

	# Try to infer from path name
	if "war_lord_turtle" in scene_path.to_lower():
		return "war_lord_turtle"
	elif "king_crab" in scene_path.to_lower():
		return "king_crab"
	elif "water_priet" in scene_path.to_lower():
		return "water_priestess"
	elif "test_boss3" in scene_path.to_lower() or "boss3" in scene_path.to_lower():
		return "boss3_water_goddess"
	elif "map_3" in scene_path.to_lower() or "map3" in scene_path.to_lower():
		return "map_3"
	elif "map1" in scene_path.to_lower() or "map_1" in scene_path.to_lower():
		return "dark_forest"
	elif "map_2" in scene_path.to_lower() or "map2" in scene_path.to_lower():
		return "dark_forest"

	return ""

func _get_images_for_content(content_key: String) -> Array[String]:
	var images: Array[String] = []
	var base_path = "res://asset/ui/loading/loading_content/images"

	# Try to load images from the specific content folder
	var content_folder = base_path.path_join(content_key)
	if DirAccess.dir_exists_absolute(content_folder):
		var dir = DirAccess.open(content_folder)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if file_name.ends_with(".png") or file_name.ends_with(".jpg") or file_name.ends_with(".jpeg"):
					images.append(content_folder.path_join(file_name))
				file_name = dir.get_next()
			dir.list_dir_end()

	# If no images found, use island images as fallback
	if images.is_empty() and content_key != "island":
		var island_folder = base_path.path_join("island")
		if DirAccess.dir_exists_absolute(island_folder):
			var dir = DirAccess.open(island_folder)
			if dir:
				dir.list_dir_begin()
				var file_name = dir.get_next()
				while file_name != "":
					if file_name.ends_with(".png") or file_name.ends_with(".jpg") or file_name.ends_with(".jpeg"):
						images.append(island_folder.path_join(file_name))
					file_name = dir.get_next()
				dir.list_dir_end()

	return images

func _get_default_images() -> Array[String]:
	# Return island images as default
	return _get_images_for_content("island")

func get_area_name(scene_path: String) -> String:
	var content = get_content_for_scene(scene_path)
	return content.get("area_name", "Unknown Lands")

func get_random_tip(scene_path: String) -> String:
	var content = get_content_for_scene(scene_path)
	var tips = content.get("tips", [])

	if tips.size() > 0:
		return tips[randi() % tips.size()]

	return "Prepare for adventure..."
