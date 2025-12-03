extends MarginContainer

@onready var music_check_button: CheckButton = $NinePatchRect/MusicCheckButton
@onready var sound_check_button: CheckButton = $NinePatchRect/SoundCheckButton
@onready var hack_check_button: CheckButton = $NinePatchRect/ModeHackCheckButton

func _ready():
	# Đồng bộ trạng thái nút với AudioServer
	if sound_check_button != null:
		sound_check_button.set_pressed_no_signal(not AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")))
	if music_check_button != null:
		music_check_button.set_pressed_no_signal(not AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")))
	if hack_check_button != null:
		hack_check_button.set_pressed_no_signal(GameManager.hack_mode_enabled)

	get_tree().paused = true

func _exit_tree() -> void:
	get_tree().paused = false

func _on_sound_check_button_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), not toggled_on)

func _on_music_check_button_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), not toggled_on)

func _on_hack_check_button_toggled(_toggled_on: bool) -> void:
	GameManager.toggle_hack_mode()

func hide_popup():
	queue_free()
		
func _on_overlay_color_rect_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		hide_popup()

func _on_close_texture_button_pressed() -> void:
	hide_popup()
