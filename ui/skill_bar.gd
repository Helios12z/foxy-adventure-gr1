extends Control

@onready var dash_icon = $Dash/Icon
@onready var dash_overlay = $Dash/Overlay
@onready var dash_label = $Dash/CoolDownLabel

@onready var sus_icon = $Susanoo/Icon
@onready var sus_overlay = $Susanoo/Overlay
@onready var sus_label = $SusanooCoolDownLabel
@onready var sus_container = $Susanoo
@onready var sus_button_label = $SusanooButtonLabel

@onready var room_container = $Room
@onready var room_icon = $Room/Icon
@onready var room_overlay = $Room/Overlay
@onready var room_label = $Room/CoolDownLabel
@onready var room_button_label = $Room/ButtonLabel

var player: Node = null
var sus_state: Node = null

func _ready() -> void:
	dash_overlay.visible = false
	dash_label.visible = false
	sus_overlay.visible = false
	sus_label.visible = false
	room_overlay.visible = false
	room_label.visible = false
	player = _find_player()
	if player != null:
		_connect_player(player)
		var states := player.get_node_or_null("States")
		if states != null:
			sus_state = states.get_node_or_null("Susanoo")
			if sus_state != null:
				_connect_susanoo(sus_state)
	_update_susanoo_visibility()
	_update_room_visibility()

func _process(_dt: float) -> void:
	if player == null:
		var p = _find_player()
		if p != null:
			player = p
			_connect_player(player)
	if sus_state == null and player != null:
		var states := player.get_node_or_null("States")
		if states != null:
			var s = states.get_node_or_null("Susanoo")
			if s != null:
				sus_state = s
				_connect_susanoo(sus_state)
	_update_susanoo_visibility()
	_update_room_visibility()

func _connect_player(p: Node) -> void:
	if p.has_signal("dash_cooldown_started"):
		if not p.is_connected("dash_cooldown_started", Callable(self, "_on_dash_cd_started")):
			p.connect("dash_cooldown_started", Callable(self, "_on_dash_cd_started"))
	if p.has_signal("dash_cooldown_updated"):
		if not p.is_connected("dash_cooldown_updated", Callable(self, "_on_dash_cd_updated")):
			p.connect("dash_cooldown_updated", Callable(self, "_on_dash_cd_updated"))
	if p.has_signal("dash_cooldown_finished"):
		if not p.is_connected("dash_cooldown_finished", Callable(self, "_on_dash_cd_finished")):
			p.connect("dash_cooldown_finished", Callable(self, "_on_dash_cd_finished"))
	if p.has_signal("room_cooldown_started"):
		if not p.is_connected("room_cooldown_started", Callable(self, "_on_room_cd_started")):
			p.connect("room_cooldown_started", Callable(self, "_on_room_cd_started"))
	if p.has_signal("room_cooldown_updated"):
		if not p.is_connected("room_cooldown_updated", Callable(self, "_on_room_cd_updated")):
			p.connect("room_cooldown_updated", Callable(self, "_on_room_cd_updated"))
	if p.has_signal("room_cooldown_finished"):
		if not p.is_connected("room_cooldown_finished", Callable(self, "_on_room_cd_finished")):
			p.connect("room_cooldown_finished", Callable(self, "_on_room_cd_finished"))

func _connect_susanoo(s: Node) -> void:
	if s.has_signal("susanoo_cooldown_started"):
		if not s.is_connected("susanoo_cooldown_started", Callable(self, "_on_sus_cd_started")):
			s.connect("susanoo_cooldown_started", Callable(self, "_on_sus_cd_started"))
	if s.has_signal("susanoo_cooldown_updated"):
		if not s.is_connected("susanoo_cooldown_updated", Callable(self, "_on_sus_cd_updated")):
			s.connect("susanoo_cooldown_updated", Callable(self, "_on_sus_cd_updated"))
	if s.has_signal("susanoo_cooldown_finished"):
		if not s.is_connected("susanoo_cooldown_finished", Callable(self, "_on_sus_cd_finished")):
			s.connect("susanoo_cooldown_finished", Callable(self, "_on_sus_cd_finished"))

func _on_dash_cd_started(duration: float) -> void:
	dash_overlay.visible = true
	dash_icon.visible = false
	dash_label.visible = true
	dash_label.text = _format_decimal(duration)

func _on_dash_cd_updated(time_left: float) -> void:
	if dash_overlay.visible:
		dash_label.text = _format_decimal(time_left)

func _on_dash_cd_finished() -> void:
	dash_overlay.visible = false
	dash_icon.visible = true
	dash_label.visible = false

func _on_sus_cd_started(duration: float) -> void:
	sus_overlay.visible = true
	sus_icon.visible = false
	sus_label.visible = true
	sus_label.text = _format_integer(duration)

func _on_sus_cd_updated(time_left: float) -> void:
	if sus_overlay.visible:
		sus_label.text = _format_integer(time_left)

func _on_sus_cd_finished() -> void:
	sus_overlay.visible = false
	sus_icon.visible = true
	sus_label.visible = false

func _update_susanoo_visibility() -> void:
	var has_gem := false
	if player != null:
		has_gem = bool(player.get("has_fire_gem"))
	if not has_gem:
		if sus_container:
			sus_container.visible = false
		if sus_button_label:
			sus_button_label.visible = false
		if sus_label:
			sus_label.visible = false
		return
	if sus_container:
		sus_container.visible = true
	if sus_button_label:
		sus_button_label.visible = true

func _update_room_visibility() -> void:
	var has_gem := false
	if player != null:
		has_gem = bool(player.get("has_water_room_gem"))
	if not has_gem:
		if room_container:
			room_container.visible = false
		if room_button_label:
			room_button_label.visible = false
		if room_label:
			room_label.visible = false
		return
	if room_container:
		room_container.visible = true
	if room_button_label:
		room_button_label.visible = true

func _on_room_cd_started(duration: float) -> void:
	room_overlay.visible = true
	room_icon.visible = false
	room_label.visible = true
	room_label.text = _format_integer(duration)

func _on_room_cd_updated(time_left: float) -> void:
	if room_overlay.visible:
		room_label.text = _format_integer(time_left)

func _on_room_cd_finished() -> void:
	room_overlay.visible = false
	room_icon.visible = true
	room_label.visible = false

func _find_player() -> Node:
	var p := get_tree().get_first_node_in_group("player")
	if p == null:
		p = get_tree().get_first_node_in_group("Player")
	if p == null:
		var root := get_tree().current_scene
		if root != null:
			p = root.get_node_or_null("Player")
	return p

func _format_decimal(v: float) -> String:
	var t = max(0.0, v)
	return String.num(t, 1)

func _format_integer(v: float) -> String:
	var t := int(ceil(max(0.0, v)))
	return str(t)
