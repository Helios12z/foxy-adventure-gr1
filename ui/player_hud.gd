extends Control

@onready var hp_bar = $HPBar
@onready var hp_label = $HPBar/HPLabel

var player
var hp_display := 0.0
var hp_target := 0.0

func _ready():
    player = get_tree().get_first_node_in_group("player")
    if player != null:
        player.connect("hp_changed", Callable(self, "_on_hp_changed"))
        _on_hp_changed(player.health, player.max_health)
        hp_display = player.health

func _on_hp_changed(current, max):
    hp_bar.max_value = max
    hp_target = current
    hp_label.text = str(current) + " / " + str(max)

func _process(delta):
    hp_display = lerp(hp_display, hp_target, delta * 10.0)
    hp_bar.value = hp_display
