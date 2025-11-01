#extends CanvasLayer
#
#@export var fade_duration: float = 1.0
#@onready var mask = $Mask
#@onready var bg = $BG
#
#func _ready() -> void:
	#visible = false
	#bg.color.a = 0  # Bắt đầu nền đen trong suốt
	#mask.scale = Vector2(3, 3)
#
#func start_fade() -> Signal:
	#visible = true
	## Fade nền đen lên
	#var tween = create_tween()
	#tween.tween_property(bg, "color:a", 1.0, fade_duration * 0.4)
	## Thu nhỏ mask lại
	#tween.parallel().tween_property(mask, "scale", Vector2(0.01, 0.01), fade_duration)
	#await tween.finished
	#emit_signal("completed")
