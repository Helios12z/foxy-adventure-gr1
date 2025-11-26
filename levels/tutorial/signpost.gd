extends Area2D

signal sword_given

@export var popup_scene: PackedScene
@export var popup_text_lines: Array[String] = []
@export var popup_keys: Array[String] = []
@export var popup_video_path: String = ""

var _player: Node = null
var _popup_instance: Control = null

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
    if body.is_in_group("Player"):
        _player = body

func _on_body_exited(body: Node) -> void:
    if body == _player:
        _player = null

func _process(_dt: float) -> void:
    if _player and Input.is_action_just_pressed("interact"):
        if _popup_instance == null:
            if popup_scene:
                var popup = popup_scene.instantiate()
                _popup_instance = popup
                var ui = get_tree().current_scene.get_node_or_null("UI")
                if ui == null:
                    ui = CanvasLayer.new()
                    ui.name = "UI"
                    get_tree().current_scene.add_child(ui)
                ui.add_child(popup)
                if "text_lines" in popup:
                    popup.text_lines = popup_text_lines
                if "keys" in popup:
                    popup.keys = popup_keys
                if "video_path" in popup:
                    popup.video_path = popup_video_path
        if _popup_instance:
            if _popup_instance.visible:
                if _player.has_method("collected_blade"):
                    _player.has_blade = true
                    _player.collected_blade()
                else:
                    if "has_blade" in _player:
                        _player.has_blade = true
                sword_given.emit()
                if _popup_instance.has_method("close_popup"):
                    _popup_instance.close_popup()
            else:
                if _popup_instance.has_method("show_popup"):
                    _popup_instance.show_popup()
