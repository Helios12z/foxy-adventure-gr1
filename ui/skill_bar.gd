extends Control

@onready var dash_icon = $Dash/Icon
@onready var dash_overlay = $Dash/Overlay
@onready var dash_label = $Dash/CoolDownLabel

@onready var sus_icon = $Susanoo/Icon
@onready var sus_overlay = $Susanoo/Overlay
@onready var sus_label = $SusanooCoolDownLabel
@onready var sus_container = $Susanoo
@onready var sus_button_label = $SusanooButtonLabel

var player: Node = null
var sus_state: Node = null

func _ready() -> void:
	dash_overlay.visible = false
	dash_label.visible = false
	sus_overlay.visible = false
	sus_label.visible = false
	player = get_tree().get_first_node_in_group("player")
	if player != null:
		_connect_player(player)
		var states := player.get_node_or_null("States")
		if states != null:
			sus_state = states.get_node_or_null("Susanoo")
			if sus_state != null:
				_connect_susanoo(sus_state)
	_update_susanoo_visibility()

func _process(_dt: float) -> void:
	if player == null:
		var p = get_tree().get_first_node_in_group("player")
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

func _format_decimal(v: float) -> String:
	var t = max(0.0, v)
	return String.num(t, 1)

func _format_integer(v: float) -> String:
	var t := int(ceil(max(0.0, v)))
	return str(t)
