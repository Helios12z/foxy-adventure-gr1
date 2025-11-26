extends Control

@onready var hp_bar = $HPBar
@onready var hp_label = $HPBar/HPLabel

@onready var susanoo_control = $Control
@onready var susanoo_hp_bar = $Control/HPBarSusanoo
@onready var susanoo_hp_label = $Control/HPBarSusanoo/HPLabel
@onready var susanoo_mana_bar = $Control/ManaBarSusanoo

var player
var hp_display := 0.0
var hp_target := 0.0

var susanoo_spirit: Node = null
var susanoo_visible: bool = false
var mana_display := 0.0
var mana_target := 0.0

func _ready():
	player = get_tree().get_first_node_in_group("player")
	if player != null:
		player.connect("hp_changed", Callable(self, "_on_hp_changed"))
		_on_hp_changed(player.health, player.max_health)
		hp_display = player.health
	if susanoo_control:
		var c = susanoo_control.modulate
		c.a = 0.0
		susanoo_control.modulate = c
		susanoo_control.visible = false

func _on_hp_changed(current, max):
	hp_bar.max_value = max
	hp_target = current
	hp_label.text = str(current) + " / " + str(max)

func _process(delta):
	hp_display = lerp(hp_display, hp_target, delta * 10.0)
	hp_bar.value = hp_display
	if player != null:
		if susanoo_spirit == null or not is_instance_valid(susanoo_spirit):
			var s = player.get_node_or_null("SusanooSpirit")
			if s != null:
				_connect_susanoo(s)
				_show_susanoo_hud()
	mana_display = lerp(mana_display, mana_target, delta * 10.0)
	if susanoo_mana_bar:
		susanoo_mana_bar.value = mana_display

func _connect_susanoo(s: Node) -> void:
	susanoo_spirit = s
	if susanoo_spirit.has_signal("attack_meter_changed"):
		if not susanoo_spirit.is_connected("attack_meter_changed", Callable(self, "_on_attack_meter_changed")):
			susanoo_spirit.connect("attack_meter_changed", Callable(self, "_on_attack_meter_changed"))
	if susanoo_spirit.has_signal("susanoo_ended"):
		if not susanoo_spirit.is_connected("susanoo_ended", Callable(self, "_on_susanoo_ended")):
			susanoo_spirit.connect("susanoo_ended", Callable(self, "_on_susanoo_ended"))
	var def := susanoo_spirit.get_node_or_null("DefenseHitArea2D")
	if def != null:
		if def.has_signal("charges_changed"):
			if not def.is_connected("charges_changed", Callable(self, "_on_charges_changed")):
				def.connect("charges_changed", Callable(self, "_on_charges_changed"))
		var m := 0
		if def.has_method("get_max_charges"):
			m = def.call("get_max_charges")
		else:
			m = int(def.get("max_charges"))
		susanoo_hp_bar.max_value = m
		var left := m
		if def.has_method("get_charges_left"):
			left = def.call("get_charges_left")
		else:
			left = int(def.get("_charges_left"))
		susanoo_hp_bar.value = left
		if susanoo_hp_label:
			susanoo_hp_label.text = str(left) + " / " + str(m)
	var threshold := 0
	if susanoo_spirit.has_method("get"):
		threshold = int(susanoo_spirit.get("meteor_attack_threshold"))
	if susanoo_mana_bar:
		susanoo_mana_bar.max_value = max(1, threshold)
		mana_target = 0.0
		mana_display = 0.0

func _show_susanoo_hud() -> void:
	if susanoo_control and not susanoo_visible:
		susanoo_control.visible = true
		var tw := create_tween()
		tw.tween_property(susanoo_control, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		susanoo_visible = true

func _hide_susanoo_hud() -> void:
	if susanoo_control and susanoo_visible:
		var tw := create_tween()
		tw.tween_property(susanoo_control, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw.tween_callback(Callable(self, "_on_hide_complete"))

func _on_hide_complete() -> void:
	if susanoo_control:
		susanoo_control.visible = false
	susanoo_visible = false

func _on_charges_changed(left: int, max: int) -> void:
	susanoo_hp_bar.max_value = max
	susanoo_hp_bar.value = left
	if susanoo_hp_label:
		susanoo_hp_label.text = str(left) + " / " + str(max)

func _on_attack_meter_changed(value: int, max: int, _triggered: bool) -> void:
	if susanoo_mana_bar:
		susanoo_mana_bar.max_value = max
	mana_target = float(value)

func _on_susanoo_ended() -> void:
	_hide_susanoo_hud()
	susanoo_spirit = null
