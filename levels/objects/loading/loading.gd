extends Control

@onready var background: TextureRect = $Background
@onready var area_name: Label = $VBoxContainer/AreaName
@onready var tip_text: Label = $VBoxContainer/TipText
@onready var loading_bar: ProgressBar = $VBoxContainer/LoadingBar
@onready var continue_prompt: Label = $VBoxContainer/ContinuePrompt
@onready var loading_dots: Label = $VBoxContainer/LoadingDots

var loading_content: Dictionary
var current_tip: String
var loading_complete: bool = false
var target_scene_path: String

func _ready():
	continue_prompt.modulate.a = 0.0
	loading_bar.value = 0.0
	loading_dots.text = "Loading..."

func start_loading(target_scene_path: String):
	# Legacy method - fallback to destination-based loading
	start_loading_with_transition("", target_scene_path)

func start_loading_with_transition(from_scene: String, to_scene: String):
	target_scene_path = to_scene
	# Load content based on transition
	if get_node_or_null("/root/LoadingManager"):
		loading_content = LoadingManager.get_content_for_transition(from_scene, to_scene)
	else:
		# Fallback content if LoadingManager is not available
		loading_content = {
			"tips": ["Loading..."],
			"area_name": "Unknown Lands",
			"loading_duration": 2.0
		}

	_setup_content()

	# Start fake loading progress
	_simulate_loading_progress()

func _setup_content():
	# Set area name
	area_name.text = loading_content.get("area_name", "Unknown Lands")

	# Set random tip
	var tips = loading_content.get("tips", [])
	if tips.size() > 0:
		var selected_tip = tips[randi() % tips.size()]
		tip_text.text = selected_tip

	# Set background image
	var images = loading_content.get("images", [])
	if images.size() > 0:
		var random_image = images[randi() % images.size()]
		background.texture = load(random_image)

func _simulate_loading_progress():
	# Start actual threaded loading
	if target_scene_path.is_empty():
		push_error("No target scene path set for loading")
		return

	# Begin threaded loading request
	var load_status = ResourceLoader.load_threaded_request(target_scene_path)
	if load_status != OK:
		push_error("Failed to start loading scene: " + target_scene_path)
		_on_loading_error()
		return

	# Track minimum visual duration to prevent flashing
	var start_time = Time.get_ticks_msec()
	var min_duration = loading_content.get("loading_duration", 2.0) * 1000  # Convert to milliseconds

	# Wait for loading to complete
	while true:
		var status = ResourceLoader.load_threaded_get_status(target_scene_path)
		var progress_array: Array = []

		# Get actual loading progress
		status = ResourceLoader.load_threaded_get_status(target_scene_path, progress_array)

		if status == ResourceLoader.THREAD_LOAD_LOADED:
			# Resource loaded, but ensure minimum visual duration
			var elapsed_time = Time.get_ticks_msec() - start_time
			if elapsed_time < min_duration:
				# Continue showing loading screen for minimum duration
				loading_bar.value = 100.0
				loading_dots.text = "Finalizing..."
				await get_tree().create_timer((min_duration - elapsed_time) / 1000.0).timeout

			loading_bar.value = 100.0
			loading_dots.text = "Loading Complete!"
			_on_loading_complete()
			break
		elif status == ResourceLoader.THREAD_LOAD_FAILED:
			push_error("Failed to load scene: " + target_scene_path)
			_on_loading_error()
			break
		elif status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			# Update progress bar with actual loading progress
			var progress = progress_array[0] * 100.0 if progress_array.size() > 0 else 0.0
			loading_bar.value = progress

			# Update loading dots animation
			var dot_count = int(Time.get_ticks_msec() / 500) % 4
			loading_dots.text = "Loading" + ".".repeat(dot_count)

			# Wait for next frame
			var tree = get_tree()
			if tree:
				await tree.process_frame
			else:
				break
		else:
			# Unknown status, wait a bit and retry
			await get_tree().create_timer(0.1).timeout

func _on_loading_complete():
	loading_complete = true
	loading_bar.value = 100.0
	loading_dots.text = "Loading Complete!"
	continue_prompt.text = "Entering level..."
	continue_prompt.modulate.a = 1.0

	# Automatically transition to the target scene after a short delay
	await get_tree().create_timer(1.0).timeout
	_load_target_scene()

func _load_target_scene():
	if target_scene_path.is_empty():
		push_error("No target scene path set")
		return

	# Get the already loaded resource from threaded loading
	var packed = ResourceLoader.load_threaded_get(target_scene_path)
	if packed:
		print("Loading scene: ", target_scene_path)
		get_tree().change_scene_to_packed(packed)
	else:
		push_error("Could not get loaded target scene: " + target_scene_path)
		_on_loading_error()

func _on_loading_error():
	loading_dots.text = "Loading Failed!"
	continue_prompt.text = "Failed to load level. Returning to start..."
	continue_prompt.modulate.a = 1.0

	# Return to tutorial map as fallback
	await get_tree().create_timer(3.0).timeout
	var fallback_scene = "res://levels/tutorial/map0.tscn"
	if FileAccess.file_exists(fallback_scene):
		get_tree().change_scene_to_file(fallback_scene)
	else:
		# Last resort: restart the current scene
		get_tree().reload_current_scene()
