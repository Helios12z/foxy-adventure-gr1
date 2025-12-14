extends Control

@onready var hp_bar = $HPBar
@onready var hp_label = $HPBar/HPLabel
@onready var mana_bar = $ManaBar
@onready var mana_label = $ManaBar/ManaLabel

@onready var susanoo_control = $Control
@onready var susanoo_hp_bar = $Control/HPBarSusanoo
@onready var susanoo_hp_label = $Control/HPBarSusanoo/HPLabel
@onready var susanoo_mana_bar = $Control/ManaBarSusanoo

var player
var hp_display := 0.0
var hp_target := 0.0

var player_mana_display := 0.0
var player_mana_target := 0.0  

var susanoo_spirit: Node = null
var susanoo_visible: bool = false
var mana_display := 0.0
var mana_target := 0.0


@onready var skill_button = $SkillTextureButton

func _ready():
	player = get_tree().get_first_node_in_group("player")
	if player != null:
		player.connect("hp_changed", Callable(self, "_on_hp_changed"))
		player.connect("mana_changed", Callable(self, "_on_mana_changed"))   

		# init HP
		_on_hp_changed(player.health, player.max_health)
		hp_display = player.health

		# init mana
		_on_mana_changed(player.mana, player.max_mana)   
		player_mana_display = player.mana                

	if susanoo_control:
		var c = susanoo_control.modulate
		c.a = 0.0
		susanoo_control.modulate = c
		susanoo_control.visible = false
	
	if skill_button:
		skill_button.pressed.connect(_on_skill_button_pressed)

func _on_skill_button_pressed() -> void:
	var skill_screen_scene = load("res://screens/game_screen/skill_screen.tscn")
	if skill_screen_scene:
		var screen = skill_screen_scene.instantiate()
		# Add to a CanvasLayer if possible, default to parent
		var root = get_tree().current_scene
		if root:
			var ui_layer = root.find_child("UILayer", true, false)
			if ui_layer:
				ui_layer.add_child(screen)
			else:
				get_parent().add_child(screen)
		else:
			add_child(screen)



func _on_hp_changed(current: int, max: int) -> void:
	if hp_bar:
		hp_bar.max_value = max
		hp_target = current
	if hp_label:
		hp_label.text = str(current) + " / " + str(max)


func _on_mana_changed(current: int, max: int) -> void:
	if mana_bar:
		mana_bar.max_value = max
		player_mana_target = current
	if mana_label:
		mana_label.text = str(current) + " / " + str(max)


func _process(delta):
	# HP Player (lerp giống mana)
	hp_display = lerp(hp_display, hp_target, delta * 10.0)
	if hp_bar:
		hp_bar.value = hp_display

	# Mana Player
	player_mana_display = lerp(player_mana_display, player_mana_target, delta * 10.0)
	if mana_bar:
		mana_bar.value = player_mana_display

	# Susanoo
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
		if player and "susanoo_level" in player:
			susanoo_mana_bar.visible = (player.susanoo_level >= 3)
		else:
			susanoo_mana_bar.visible = false


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
