extends BaseCharacter

@export var spike_damage: int = 70
@export var attack_speed: float = 50.0       
@export var attack_damage_boss: int = 50     
@export var bomb_move_speed: float = 50.0 
@export var fatigue_seconds_after_skill2: float = 2.0

@export var bomb_scene: PackedScene
@export var missile_scene: PackedScene

@onready var atk_1_shoot_point_1: Marker2D = $Direction/Atk1ShootPoint1
@onready var atk_1_shoot_point_2: Marker2D = $Direction/Atk1ShootPoint2
@onready var atk_2_shoot_point_1: Marker2D = $Direction/Atk2ShootPoint1
@onready var atk_2_shoot_point_2: Marker2D = $Direction/Atk2ShootPoint2

func _ready() -> void:
	super._ready()
	
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
