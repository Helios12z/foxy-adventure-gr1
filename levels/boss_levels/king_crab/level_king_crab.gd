extends Node2D

@onready var boss_hud: Control = $CanvasLayer/BossHUD
@onready var boss: CharacterBody2D = $World/KingCrab

func _ready() -> void:
	boss_hud.set_boss(boss)
