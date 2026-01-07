extends CanvasLayer
class_name ComicViewer

signal finished

@export var pages: Array[Texture2D] = []
@export var overlay_color: Color = Color(0, 0, 0, 1)
@export var page_margin_px: int = 0

# Auto-play / Music Sync configuration
@export var bgm: AudioStream
@export var transition_timestamps: Array = []

var _current_index: int = 0
var _paused_before: bool = false

var _audio_player: AudioStreamPlayer
var _transition_rect: TextureRect
var _next_page_target_idx: int = 0
var _elapsed_time: float = 0.0

# Call this before adding to scene tree to configure auto-play
func setup_auto_play(audio_stream: AudioStream, timestamps: Array) -> void:
	bgm = audio_stream
	transition_timestamps = timestamps.duplicate()
	print("[ComicViewer] Setup auto-play - BGM: ", bgm != null, ", Timestamps: ", transition_timestamps)

func _ready() -> void:
	if has_node("Overlay"):
		var overlay: ColorRect = $Overlay
		overlay.color = overlay_color
	
	# Create a transition rect for crossfading
	if has_node("PageTexture"):
		var original: TextureRect = $PageTexture
		_transition_rect = original.duplicate()
		_transition_rect.name = "TransitionTexture"
		_transition_rect.modulate.a = 0
		_transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_transition_rect)

	# Khi hiển thị ComicViewer, pause toàn bộ game/scene và vẫn xử lý input của viewer
	process_mode = Node.PROCESS_MODE_ALWAYS
	var tree := get_tree()
	if tree:
		_paused_before = tree.paused
		tree.paused = true
	
	_update_bounds()
	_update_page()
	
	if has_node("NextButton/Button"):
		var btn: Button = $NextButton/Button
		btn.pressed.connect(_on_next_pressed)
	
	get_viewport().size_changed.connect(_on_viewport_resized)

	# Handle Auto Play Logic
	if bgm:
		_start_auto_play()
		# Hide Next button when auto-playing, show it only on last page
		# Modify: Next button always visible, serving as Skip button
		if has_node("NextButton/Button"):
			$NextButton/Button.visible = true

func _start_auto_play() -> void:
	_audio_player = AudioStreamPlayer.new()
	_audio_player.stream = bgm
	_audio_player.process_mode = Node.PROCESS_MODE_ALWAYS
	_audio_player.finished.connect(_on_audio_finished)
	add_child(_audio_player)
	_audio_player.play()
	
	_next_page_target_idx = 0
	print("[ComicViewer] Auto-play started. Timestamps count: ", transition_timestamps.size())
	
	# Start winter morning ambient for images 1, 2, 3
	_winter_player = AudioStreamPlayer.new()
	var winter_stream = load("res://asset/sounds/Winter Morning Ambience Sound Effect  Copyright Free Nature Sounds - Audio Wind.mp3")
	_winter_player.stream = winter_stream
	_winter_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_winter_player)
	_winter_player.play()
	# Make it loop
	_winter_player.finished.connect(func(): 
		if _winter_player and is_instance_valid(_winter_player):
			_winter_player.play()
	)

var _sea_waves_player: AudioStreamPlayer = null

func _process(delta: float) -> void:
	if _audio_player:
		# Use delta time accumulation which is safer than relying on audio playback position
		# especially when pausing/unpausing or if audio fails to play.
		if _audio_player.playing:
			# Soft sync: if audio is running, try to stay close to it, 
			# but don't let it block progress if audio glitches.
			var audio_pos = _audio_player.get_playback_position()
			if audio_pos > _elapsed_time:
				_elapsed_time = audio_pos
			else:
				_elapsed_time += delta
		else:
			# If audio finished or hasn't started, just run on timer
			_elapsed_time += delta

		if _next_page_target_idx < transition_timestamps.size():
			var trigger_time = transition_timestamps[_next_page_target_idx]
			if _elapsed_time >= trigger_time:
				var destination_page = _next_page_target_idx + 1
				_next_page_target_idx += 1
				
				if destination_page < pages.size() and destination_page != _current_index:
					_smooth_transition_to_page(destination_page)

func _on_audio_finished() -> void:
	# "hết nhạc thì tới ảnh 9" (Index 8)
	if pages.size() > 0:
		var last_idx = pages.size() - 1
		if _current_index != last_idx:
			_smooth_transition_to_page(last_idx)

var _thunder_player: AudioStreamPlayer = null
var _rain_player: AudioStreamPlayer = null
var _winter_player: AudioStreamPlayer = null
var _splash_player: AudioStreamPlayer = null
var _scream_player: AudioStreamPlayer = null

func _smooth_transition_to_page(index: int) -> void:
	if index < 0 or index >= pages.size():
		return
		
	# Setup transition
	_current_index = index
	var next_tex = pages[index]
	
	# Modify: Next button is always visible now
	# if index == 8 and has_node("NextButton/Button"):
	# 	$NextButton/Button.visible = true
	
	# Start sea waves ambient from image 2 (index 1)
	if index == 1 and not _sea_waves_player:
		_sea_waves_player = AudioStreamPlayer.new()
		var waves_stream = load("res://asset/sounds/Sea Waves - Sound Effect - Sound Effects.mp3")
		_sea_waves_player.stream = waves_stream
		_sea_waves_player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(_sea_waves_player)
		_sea_waves_player.play()
		# Make it loop
		_sea_waves_player.finished.connect(func(): 
			if _sea_waves_player and is_instance_valid(_sea_waves_player):
				_sea_waves_player.play()
		)
	
	# Stop winter morning ambient when reaching image 5 (index 4)
	if index == 4 and _winter_player:
		_winter_player.stop()
		_winter_player.queue_free()
		_winter_player = null
	
	# Play looping thunder sound starting from image 4 (index 3)
	if index == 3 and not _thunder_player:
		_thunder_player = AudioStreamPlayer.new()
		var thunder_stream = load("res://asset/sounds/Free Thunder Sound Effect  No Copyright - Friendly Free Sounds.mp3")
		_thunder_player.stream = thunder_stream
		_thunder_player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(_thunder_player)
		_thunder_player.play()
		# Make it loop by reconnecting to finished signal
		_thunder_player.finished.connect(func(): 
			if _thunder_player and is_instance_valid(_thunder_player):
				_thunder_player.play()
		)
	
	# Play looping rain sound starting from image 5 (index 4)
	if index == 4 and not _rain_player:
		_rain_player = AudioStreamPlayer.new()
		var rain_stream = load("res://asset/sounds/Rain.mp3")
		_rain_player.stream = rain_stream
		_rain_player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(_rain_player)
		_rain_player.play()
		# Make it loop
		_rain_player.finished.connect(func(): 
			if _rain_player and is_instance_valid(_rain_player):
				_rain_player.play()
		)
	
	# Play water splash sound once for image 6 (index 5)
	if index == 5:
		_splash_player = AudioStreamPlayer.new()
		_splash_player.stream = load("res://asset/sounds/water_prietess_sound/water_splash.mp3")
		_splash_player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(_splash_player)
		_splash_player.play()
		# Auto cleanup after playing
		_splash_player.finished.connect(func(): 
			if _splash_player:
				_splash_player.queue_free()
				_splash_player = null
		)
		
		# Play scream sound once for image 6
		_scream_player = AudioStreamPlayer.new()
		_scream_player.stream = load("res://asset/sounds/ES_Pained Scream Male, Scream - Epidemic Sound.mp3")
		_scream_player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(_scream_player)
		_scream_player.play()
		# Auto cleanup after playing
		_scream_player.finished.connect(func(): 
			if _scream_player:
				_scream_player.queue_free()
				_scream_player = null
		)
	
	# Stop thunder when reaching image 7 (index 6)
	if index == 6:
		# Stop splash and scream immediately when leaving image 6
		if _splash_player:
			_splash_player.stop()
			_splash_player.queue_free()
			_splash_player = null
		if _scream_player:
			_scream_player.stop()
			_scream_player.queue_free()
			_scream_player = null
		
		# Stop thunder
		if _thunder_player:
			_thunder_player.stop()
			_thunder_player.queue_free()
			_thunder_player = null
	
	# Restart winter morning ambient at image 8 (index 7)
	if index == 7 and not _winter_player:
		_winter_player = AudioStreamPlayer.new()
		var winter_stream = load("res://asset/sounds/Winter Morning Ambience Sound Effect  Copyright Free Nature Sounds - Audio Wind.mp3")
		_winter_player.stream = winter_stream
		_winter_player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(_winter_player)
		_winter_player.play()
		# Make it loop
		_winter_player.finished.connect(func(): 
			if _winter_player and is_instance_valid(_winter_player):
				_winter_player.play()
		)
	
	# Stop rain when reaching image 8 (index 7)
	if index == 7 and _rain_player:
		_rain_player.stop()
		_rain_player.queue_free()
		_rain_player = null
	
	if not has_node("PageTexture") or not _transition_rect:
		# Fallback if setup failed
		if has_node("PageTexture"):
			$PageTexture.texture = next_tex
		return
		
	_transition_rect.texture = next_tex
	_transition_rect.modulate.a = 0.0
	
	var tween = create_tween()
	tween.set_parallel(false)
	# Smooth fade - 0.8s for nice video feel
	tween.tween_property(_transition_rect, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():
		var pt = get_node("PageTexture")
		if pt:
			pt.texture = next_tex
		_transition_rect.modulate.a = 0.0
	)

func _on_next_pressed() -> void:
	# Modify: Next button now acts as Skip button
	finished.emit()
	_close_and_resume()

func _update_page() -> void:
	if not has_node("PageTexture"):
		return
	var texrect: TextureRect = $PageTexture
	texrect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if _current_index >= 0 and _current_index < pages.size():
		texrect.texture = pages[_current_index]
	else:
		texrect.texture = null
	
	if _transition_rect:
		_transition_rect.modulate.a = 0.0

func _update_bounds() -> void:
	if not has_node("PageTexture"):
		return
	var texrect: TextureRect = $PageTexture
	_apply_bounds_to(texrect)
	
	if _transition_rect:
		_apply_bounds_to(_transition_rect)

func _apply_bounds_to(texrect: TextureRect) -> void:
	texrect.anchor_left = 0.0
	texrect.anchor_top = 0.0
	texrect.anchor_right = 1.0
	texrect.anchor_bottom = 1.0
	texrect.offset_left = page_margin_px
	texrect.offset_top = page_margin_px
	texrect.offset_right = -page_margin_px
	texrect.offset_bottom = -page_margin_px

func _on_viewport_resized() -> void:
	_update_bounds()

func _close_and_resume() -> void:
	# Đóng viewer và resume lại trạng thái pause trước đó
	var tree := get_tree()
	if tree:
		tree.paused = _paused_before
	queue_free()
