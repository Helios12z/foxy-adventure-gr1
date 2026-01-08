extends Node2D
## Upward Platform with one-way collision
## Allows player to jump through from below but land on top

@export var hide_until_waves_cleared: bool = false

@onready var static_body: StaticBody2D = $StaticBody2D
@onready var collision_shape: CollisionShape2D = $StaticBody2D/CollisionShape2D
@onready var sprite: Sprite2D = $StaticBody2D/Sprite2D if $StaticBody2D.has_node("Sprite2D") else null

var _player_detector: Area2D = null
var _player_in_area: Node = null  # Track player currently in detector area
var _check_timer: Timer = null
var _stability_time: float = 0.0  # Track how long player has been standing stably
const STABILITY_THRESHOLD: float = 0.4  # Player must stand stably for 0.4 seconds

# Static variable shared across all platform instances
static var _camera_triggered: bool = false
static var _player_reached_platforms: bool = false  # Track if player has reached any platform
static var _last_platform_position: Vector2 = Vector2.ZERO  # Track last platform player stood on

func _ready() -> void:
	# Set up one-way collision for jumping through from below
	if static_body:
		static_body.collision_layer = 1  # Platform layer
		static_body.collision_mask = 0   # Doesn't collide with anything itself

	# Enable one-way collision on the collision shape
	if collision_shape:
		collision_shape.one_way_collision = true
		collision_shape.one_way_collision_margin = 1.0  # Small margin for smooth collision

	# EXTENSION: Hide until waves cleared in boss room
	if hide_until_waves_cleared:
		visible = false
		if collision_shape:
			collision_shape.disabled = true
	else:
		# Only set up detector if platform is visible from start
		_setup_player_detector()


# ===========================
# EXTENSION: Boss Room API
# ===========================

## PUBLIC API: Show platform after waves cleared in boss room
func show_after_waves_cleared() -> void:
	if not hide_until_waves_cleared:
		return

	print("[UpwardPlatform] Waves cleared! Showing platform")

	# Show the platform with fade-in
	visible = true
	if sprite:
		sprite.modulate.a = 0.0
		var fade_tween = create_tween()
		fade_tween.tween_property(sprite, "modulate:a", 1.0, 1.0)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_IN_OUT)

	# Enable collision
	if collision_shape:
		collision_shape.disabled = false

	# Set up player detector after platform is shown
	if not _player_detector and static_body:
		_setup_player_detector()


func _setup_player_detector() -> void:
	"""Set up an Area2D to detect when player lands on this platform"""
	if not static_body:
		print("[UpwardPlatform] ERROR: No static_body found for platform: %s" % name)
		return

	_player_detector = Area2D.new()
	_player_detector.name = "PlayerDetector"
	_player_detector.collision_layer = 0
	_player_detector.collision_mask = 2  # Player layer
	_player_detector.monitoring = true
	_player_detector.monitorable = false
	static_body.add_child(_player_detector)

	# Create detection shape above the platform
	var detect_shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()

	# Get platform size from collision shape
	if collision_shape and collision_shape.shape is RectangleShape2D:
		var platform_size = (collision_shape.shape as RectangleShape2D).size
		rect.size = Vector2(platform_size.x, 30.0)  # Wide as platform, 30 pixels tall
		detect_shape.position = Vector2(0, -15.0)  # Position above the platform
		print("[UpwardPlatform] Platform %s: detector size = %v at position %v" % [name, rect.size, detect_shape.position])
	else:
		# Default size
		rect.size = Vector2(100.0, 30.0)
		detect_shape.position = Vector2(0, -15.0)
		print("[UpwardPlatform] Platform %s: using default detector size" % name)

	detect_shape.shape = rect
	_player_detector.add_child(detect_shape)

	# Connect signals for entry and exit
	_player_detector.body_entered.connect(_on_player_entered_area)
	_player_detector.body_exited.connect(_on_player_exited_area)

	# Create a timer to check if player is standing on platform
	_check_timer = Timer.new()
	_check_timer.wait_time = 0.05  # Faster check rate for web compatibility (was 0.1)
	_check_timer.one_shot = false
	_check_timer.timeout.connect(_check_player_standing)
	add_child(_check_timer)

	print("[UpwardPlatform] ✓ Player detector set up for platform: %s (collision_mask=2)" % name)


func _on_player_entered_area(body: Node) -> void:
	"""Called when player enters the detector area"""
	print("[UpwardPlatform] Body entered area on platform %s: %s" % [name, body.name])

	if not body.is_in_group("Player"):
		return

	_player_in_area = body
	_check_timer.start()
	print("[UpwardPlatform] Player entered detector, starting check timer")


func _on_player_exited_area(body: Node) -> void:
	"""Called when player exits the detector area"""
	if body == _player_in_area:
		_player_in_area = null
		_check_timer.stop()
		_stability_time = 0.0  # Reset stability counter
		print("[UpwardPlatform] Player exited detector on platform %s" % name)


func _check_player_standing() -> void:
	"""Periodically check if player is standing on this platform"""
	if not _player_in_area or not is_instance_valid(_player_in_area):
		_check_timer.stop()
		_player_in_area = null
		_stability_time = 0.0  # Reset stability counter
		return

	# Multi-condition check for better web compatibility
	var is_standing = false

	# Condition 1: Traditional is_on_floor check (works on native)
	if "is_on_floor" in _player_in_area and _player_in_area.is_on_floor():
		is_standing = true

	# Condition 2: Velocity check (reliable on web)
	# If player's Y velocity is small and they're in the area, they've landed
	if "velocity" in _player_in_area:
		var vel_y = _player_in_area.velocity.y
		# Player is standing if falling velocity is very small (between -50 and +50)
		if abs(vel_y) < 50.0:
			is_standing = true

	# Condition 3: Position check (extra reliability for web)
	# Check if player's bottom is within a few pixels of platform's top
	if collision_shape and collision_shape.shape is RectangleShape2D:
		var platform_top_y = static_body.global_position.y + collision_shape.position.y - (collision_shape.shape as RectangleShape2D).size.y / 2.0
		var player_bottom_y = _player_in_area.global_position.y
		var distance_to_platform = player_bottom_y - platform_top_y

		# If player is within 20 pixels above the platform surface, consider them standing
		if distance_to_platform >= -5.0 and distance_to_platform <= 20.0:
			is_standing = true

	# Track stability over time
	if is_standing:
		_stability_time += _check_timer.wait_time
		print("[UpwardPlatform] Player standing stably on %s (%.2f/%.2f sec)" % [name, _stability_time, STABILITY_THRESHOLD])

		# Only trigger after player has been standing stably for the threshold duration
		if _stability_time >= STABILITY_THRESHOLD:
			print("[UpwardPlatform] Player CONFIRMED stably standing on platform %s!" % name)
			_check_timer.stop()
			_trigger_platform_event()
	else:
		# Player is not standing stably, reset the counter
		if _stability_time > 0.0:
			print("[UpwardPlatform] Player lost stability, resetting counter")
		_stability_time = 0.0


func _trigger_platform_event() -> void:
	"""Trigger the coral spikes and camera when player stands on platform"""
	# Track the last platform position for coral spike respawn
	_last_platform_position = global_position
	print("[UpwardPlatform] *** Updated last platform position: %v" % _last_platform_position)

	# Mark that player has reached platforms (for boss to resume skills)
	_player_reached_platforms = true
	print("[UpwardPlatform] *** Player reached platforms! Boss can resume skills ***")

	# Enable coral spikes when player reaches platforms (only once)
	if not _camera_triggered:
		_enable_coral_spikes()
		_hide_all_bubbles()

	# Only trigger once across all platforms
	if _camera_triggered:
		print("[UpwardPlatform] Camera already triggered, ignoring")
		return

	_camera_triggered = true
	print("[UpwardPlatform] ========== PLAYER LANDED ON PLATFORM %s! ==========" % name)
	print("[UpwardPlatform] Triggering camera scroll-up...")

	# Find the Phase3Camera
	var camera = get_tree().get_first_node_in_group("Phase3Camera")
	print("[UpwardPlatform] Found camera: %s" % camera)

	if camera and camera.has_method("scroll_to_upper_room"):
		print("[UpwardPlatform] Calling scroll_to_upper_room()...")
		camera.scroll_to_upper_room()
		print("[UpwardPlatform] Camera scroll triggered successfully!")
	else:
		print("[UpwardPlatform] ERROR: Phase3Camera not found or doesn't have scroll_to_upper_room method")


func _enable_coral_spikes() -> void:
	"""Enable all coral spikes when player reaches platforms"""
	print("[UpwardPlatform] === ATTEMPTING TO ENABLE CORAL SPIKES ===")

	var coral_spikes_node = get_tree().current_scene.get_node_or_null("CoralSpikes")
	if not coral_spikes_node:
		print("[UpwardPlatform] ✗ CoralSpikes node not found in current_scene")
		print("[UpwardPlatform] Current scene: %s" % get_tree().current_scene.name)
		return

	print("[UpwardPlatform] ✓ Found CoralSpikes node")
	print("[UpwardPlatform] CoralSpikes children count: %d" % coral_spikes_node.get_child_count())

	# First enable the parent node
	coral_spikes_node.process_mode = Node.PROCESS_MODE_INHERIT
	coral_spikes_node.visible = true
	print("[UpwardPlatform] ✓ Enabled CoralSpikes parent node")

	# Enable the under-spike static body if it exists
	var under_static_body = coral_spikes_node.get_node_or_null("UnderCoralStaticBody2D")
	if under_static_body and under_static_body is StaticBody2D:
		under_static_body.process_mode = Node.PROCESS_MODE_INHERIT
		under_static_body.visible = true
		# Enable the collision shape inside it
		var collision_shape = under_static_body.get_node_or_null("CollisionShape2D")
		if collision_shape:
			collision_shape.disabled = false
			print("[UpwardPlatform] ✓ Enabled UnderCoralStaticBody2D and its collision shape")
		else:
			print("[UpwardPlatform] ✓ Enabled UnderCoralStaticBody2D (no collision shape found)")
	else:
		print("[UpwardPlatform] ℹ UnderCoralStaticBody2D not found (not added yet)")

	# Then enable all children
	print("[UpwardPlatform] Enabling all coral spike children...")
	var spike_count = 0
	for child in coral_spikes_node.get_children():
		print("[UpwardPlatform] Processing child: %s (type: %s)" % [child.name, child.get_class()])
		if "Boss3CoralSpike" in child.name:
			child.process_mode = Node.PROCESS_MODE_INHERIT
			child.visible = true

			# Manually initialize the coral spike script since _ready() might not have run
			if child.has_method("initialize_after_enable"):
				child.initialize_after_enable()
				print("[UpwardPlatform]   ✓ Initialized coral spike script")

			spike_count += 1
			print("[UpwardPlatform] ✓ Enabled coral spike: %s" % child.name)

	print("[UpwardPlatform] ✓ Enabled %d coral spikes!" % spike_count)


func _hide_all_bubbles() -> void:
	"""Hide all bubbles when player reaches the top"""
	print("[UpwardPlatform] Hiding all bubbles (using Group 'BubblePlatform')...")
	
	var bubbles = get_tree().get_nodes_in_group("BubblePlatform")
	
	# Fallback if group is empty (just in case)
	if bubbles.is_empty():
		print("[UpwardPlatform] ✗ No nodes found in group 'BubblePlatform'")
		print("[UpwardPlatform] Attempting fallback search under 'Platforms'...")
		
		var platforms_node = get_tree().current_scene.find_child("Platforms", true, false)
		if not platforms_node:
			platforms_node = get_tree().current_scene.get_node_or_null("Platforms")
			
		if platforms_node:
			for child in platforms_node.get_children():
				if "Bubble" in child.name:
					child.visible = false
					if child is StaticBody2D:
						var collision = child.get_node_or_null("CollisionShape2D")
						if collision:
							collision.set_deferred("disabled", true)
					print("[UpwardPlatform] ✓ Hidden bubble (fallback): %s" % child.name)
		else:
			print("[UpwardPlatform] ✗ Platforms node not found for fallback")
		return

	# Hide all bubbles found in group
	for bubble in bubbles:
		# Hide visual
		bubble.visible = false
		
		# Disable collision
		if bubble is StaticBody2D:
			var collision = bubble.get_node_or_null("CollisionShape2D")
			if collision:
				collision.set_deferred("disabled", true)
		
		print("[UpwardPlatform] ✓ Hidden bubble: %s" % bubble.name)
