extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit: HitArea2D = $HitArea2D
@onready var eruption_sound: AudioStreamPlayer = null  # Will be set from boss

@export var fade_duration := 0.25
@export var active_time := 1.0

var _is_playing := false  # Track if eruption is currently playing
var _first_play := true  # Track if this is first time playing

func _ready() -> void:
	print("SELF =", self)
	print("CHILDREN =", get_children())
	print("FIND Sprite2D =", get_node_or_null("Sprite2D"))

func play():
	# Prevent interruption if already playing
	if _is_playing:
		print("[WaterEruption] Already playing, skipping")
		return

	_is_playing = true
	_reset_state()

	# On first play, wait one extra frame to ensure nodes are ready
	if _first_play:
		# Check if still in tree before awaiting
		if not is_inside_tree():
			_is_playing = false
			return
		await get_tree().process_frame
		_first_play = false

	# Check if still valid after await
	if not is_inside_tree():
		_is_playing = false
		return

	await _fade_out(sprite, fade_duration)

	# Check if still valid after fade
	if not is_inside_tree():
		_is_playing = false
		return

	# Play sound right when attack starts (animation becomes visible)
	if eruption_sound:
		eruption_sound.play()

	anim.visible = true
	anim.modulate.a = 1.0
	anim.play("default")
	hit.set_deferred("monitoring", true)
	hit.set_deferred("monitorable", true)

	# Check if still in tree before awaiting timer
	if not is_inside_tree():
		_is_playing = false
		return

	await get_tree().create_timer(active_time).timeout

	# Check if still valid after timer
	if not is_inside_tree():
		_is_playing = false
		return

	await _fade_out(anim, fade_duration)

	# Check if still valid after fade
	if not is_inside_tree():
		_is_playing = false
		return

	anim.visible = false
	hit.set_deferred("monitoring", false)
	hit.set_deferred("monitorable", false)

	_is_playing = false  # Reset flag when done



func _reset_state():
	anim.visible = false
	anim.modulate.a = 0.0
	sprite.visible = true
	sprite.modulate.a = 1.0
	anim.stop()
	hit.set_deferred("monitoring", false)
	hit.set_deferred("monitorable", false)



func _fade_out(node: Node2D, duration: float) -> void:
	# Check if node is valid before starting
	if not is_instance_valid(node) or not is_inside_tree():
		return

	var start := node.modulate.a
	var t := 0.0
	while t < duration:
		# Check if we're still in the tree before awaiting
		if not is_inside_tree():
			return

		t += get_process_delta_time()
		var k := 1.0 - (t / duration)
		node.modulate.a = start * k
		await get_tree().process_frame

		# Check again after await in case node was freed during the frame
		if not is_instance_valid(node) or not is_inside_tree():
			return

	# Final checks before setting properties
	if is_instance_valid(node) and is_inside_tree():
		node.modulate.a = 0.0
		node.visible = false


func stop() -> void:
	"""Stop the eruption immediately and reset state"""
	_is_playing = false
	_reset_state()
