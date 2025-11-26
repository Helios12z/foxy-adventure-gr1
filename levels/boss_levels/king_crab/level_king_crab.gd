extends Node2D

@onready var boss_hud: Control = $CanvasLayer/BossHUD
@onready var boss: CharacterBody2D = $World/KingCrab
@onready var boss_platform_controller: Node2D = $World/BossPlatformController

func _ready() -> void:
	boss_hud.set_boss(boss)
	
	if not boss.start_fight.is_connected(_on_boss_start_fight):
		boss.start_fight.connect(_on_boss_start_fight)

	if not boss.boss_died.is_connected(_on_boss_died):
		boss.boss_died.connect(_on_boss_died)
		
	if not boss_platform_controller.complete_moving_up.is_connected(_on_complete_moving_up):
		boss_platform_controller.complete_moving_up.connect(_on_complete_moving_up)

func _on_boss_start_fight() -> void:
	boss_platform_controller.start_boss_intro()

func _on_boss_died() -> void:
	boss_platform_controller.return_platform_after_boss_dead()
	
func _on_complete_moving_up() -> void:
	boss.seen_player = true 
	boss_hud._on_boss_start_fighting()
