extends CanvasLayer
class_name ComicViewer

signal finished

@export var pages: Array[Texture2D] = []
@export var overlay_color: Color = Color(0, 0, 0, 1)
@export var page_margin_px: int = 0

var _current_index: int = 0
var _paused_before: bool = false

func _ready() -> void:
	if has_node("Overlay"):
		var overlay: ColorRect = $Overlay
		overlay.color = overlay_color
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

func _on_next_pressed() -> void:
	_current_index += 1
	if _current_index >= pages.size():
		finished.emit()
		_close_and_resume()
		return
	_update_page()

func _update_page() -> void:
	if not has_node("PageTexture"):
		return
	var texrect: TextureRect = $PageTexture
	texrect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if _current_index >= 0 and _current_index < pages.size():
		texrect.texture = pages[_current_index]
	else:
		texrect.texture = null

func _update_bounds() -> void:
	if not has_node("PageTexture"):
		return
	var texrect: TextureRect = $PageTexture
	# Fill the viewport and apply margins via offsets so layout stays correct
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
