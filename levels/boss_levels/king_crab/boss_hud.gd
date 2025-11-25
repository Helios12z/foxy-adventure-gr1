extends Control

@onready var bar: TextureProgressBar = $BossHealthBar

var _boss: Node = null

func set_boss(boss: Node) -> void:
	_boss = boss
	if not _boss:
		visible = false
		return

	if not _boss.health_changed.is_connected(_on_boss_health_changed):
		_boss.health_changed.connect(_on_boss_health_changed)
	if not _boss.boss_died.is_connected(_on_boss_died):
		_boss.boss_died.connect(_on_boss_died)

	_on_boss_health_changed(_boss.health, _boss.max_health)
	visible = true

func _on_boss_health_changed(current: float, max_health: float) -> void:
	bar.max_value = max_health
	bar.value = current

func _on_boss_died() -> void:
	visible = false
