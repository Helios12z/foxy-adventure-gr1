extends EnemyCharacter

signal boss_died
signal health_changed(current: float, max_health: float)
signal start_appearing

@export var attack_windup_time: float = 0.8
@export var boss_health: int = 650
@export var boss_attack_damage: int = 30
@export var boss_speed: float = 40.0
@export var attack_cooldown: float = 1.25

@onready var animated_sprite_2d: AnimatedSprite2D = $Direction/AnimatedSprite2D
@onready var attack_collision_shape_2d: CollisionShape2D = $Direction/AttackHitArea2D/CollisionShape2D
@onready var hurt_collision_shape_2d: CollisionShape2D = $Direction/HurtArea2D/CollisionShape2D
@onready var hit_collision_shape_2d: CollisionShape2D = $Direction/HitArea2D/CollisionShape2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var detect_front = $Direction/DetectFrontRayCast2D
@onready var detect_back = $Direction/DetectBackRayCast2D
@onready var attack_scope_ray_cast = $Direction/AttackScopeRayCast2D
@onready var hit_area_2d: HitArea2D = $Direction/HitArea2D

@onready var boss_music: AudioStreamPlayer2D = $Sound/BossMusic
@onready var attack: AudioStreamPlayer2D = $Sound/Attack
@onready var walking: AudioStreamPlayer2D = $Sound/Walking

var _flash_tw: Tween

func _ready() -> void:
	max_health = boss_health
	hit_area_2d.damage = boss_attack_damage
	super._ready()
	_init_hurt_area()
	fsm = FSM.new(self, $States, $States/Sleep)
	collision_shape_2d.disabled = true 
	attack_collision_shape_2d.disabled = true 
	hurt_collision_shape_2d.disabled = true  
	hit_collision_shape_2d.disabled = true    
	if not start_appearing.is_connected(_on_start_appearing):
		start_appearing.connect(_on_start_appearing)             

func can_detect_player() -> bool:
	if detect_front.is_colliding():
		return true

	if detect_back.is_colliding():
		turn_around()
		_check_changed_direction()
		return true

	return false

func is_in_attack_scope() -> bool:
	if attack_scope_ray_cast.is_colliding():
		return true
	return false
	
func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if health <= 0:
		fsm.change_state(fsm.states.dead)
		return

func _on_start_appearing() -> void:
	fsm.change_state(fsm.states.appear)

func _init_hurt_area() -> void:
	if has_node("Direction/HurtArea2D"):
		var hurt_area = $Direction/HurtArea2D
		hurt_area.hurt.connect(_on_hurt_area_2d_hurt)

func _on_hurt_area_2d_hurt(_dir: Vector2, damage: float) -> void:
	take_damage(damage)
	emit_signal("health_changed", health, max_health)
	
	if fsm.current_state != fsm.states.idle:
		flash_hurt(0.25, 3)

	if health <= 0.0:
		if fsm and fsm.current_state != fsm.states.dead:
			fsm.change_state(fsm.states.dead)
		return

	if fsm.current_state == fsm.states.idle:
		fsm.change_state(fsm.states.hurt)

func flash_hurt(duration := 0.25, blinks := 3, color := Color(1, 0.2, 0.2, 1)) -> void:
	var mat := animated_sprite_2d.material as ShaderMaterial
	if mat == null:
		return

	mat.set_shader_parameter("flash_color", color)
	mat.set_shader_parameter("flash_amount", 0.0)

	if is_instance_valid(_flash_tw):
		_flash_tw.kill()

	_flash_tw = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var step := duration / float(blinks * 2)
	for i in blinks:
		_flash_tw.tween_property(mat, "shader_parameter/flash_amount", 1.0, step)
		_flash_tw.tween_property(mat, "shader_parameter/flash_amount", 0.0, step)
