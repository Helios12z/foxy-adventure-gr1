extends EnemyCharacter

@onready var water: AnimatedSprite2D = $Water
@onready var tornado: AnimatedSprite2D = $Tornado
@onready var hurt_area_2d: HurtArea2D = $HurtArea2D
@onready var hit_area_2d: HitArea2D = $HitArea2D

@export var minion_health: int = 75
@export var tornado_damage: int = 10
@export var lifetime: float = 15.0            

var _alive_time: float = 0.0
var _blink_tw: Tween

func _ready() -> void:
	max_health = minion_health
	super._ready()
	fsm = FSM.new(self, $States, $States/Water)

	water.visible = true
	tornado.visible = false

	hurt_area_2d.hurt.connect(_on_hurt_area_2d_hurt)
	hit_area_2d.damage = tornado_damage
	hit_area_2d.monitoring = false
	hit_area_2d.monitorable = false
	
	add_to_group("water_tornado")

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	_alive_time += delta
	if _alive_time >= lifetime and fsm.current_state != fsm.states.dead:
		fsm.change_state(fsm.states.dead)

func _on_hurt_area_2d_hurt(_direction: Variant, damage: Variant) -> void:
	super._on_hurt_area_2d_hurt(Vector2.ZERO, damage)

func _start_warning_blink(total: float, times: int) -> void:
	var mat := water.material as ShaderMaterial
	if mat == null:
		return

	mat.set_shader_parameter("flash_color", Color(1.0, 0.8, 0.2, 1.0))
	mat.set_shader_parameter("flash_amount", 0.0)

	if is_instance_valid(_blink_tw):
		_blink_tw.kill()

	_blink_tw = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var step = max(total / float(times * 2), 0.01)
	for i in range(times):
		_blink_tw.tween_property(mat, "shader_parameter/flash_amount", 1.0, step)
		_blink_tw.tween_property(mat, "shader_parameter/flash_amount", 0.0, step)
		
func _stop_blink() -> void:
	if is_instance_valid(_blink_tw):
		_blink_tw.kill()
	var mat := water.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("flash_amount", 0.0)
