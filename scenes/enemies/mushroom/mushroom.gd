extends EnemyCharacter

@export var minion_health: int = 50
@export var explode_warning_time: float = 1.0
@export var explode_damage: int = 40
@export var detection_range: float = 60.0

@onready var hurt_area = $Direction/HurtArea2D
@onready var detect_front: RayCast2D = $Direction/DetectFrontRayCast2D
@onready var animated_sprite_2d: AnimatedSprite2D = $Direction/AnimatedSprite2D
@onready var explode_effect: AnimatedSprite2D = $ExplodeEffect
@onready var explode_hit_area: HitArea2D = $ExplodeHitArea

var is_exploding: bool = false
var warning_timer: float = 0.0
var _flash_tw: Tween

func _ready() -> void:
	max_health = minion_health
	super._ready()
	fsm = FSM.new(self, $States, $States/Walk)
	hurt_area.hurt.connect(_on_hurt_area_2d_hurt)

	# Setup explode hit area
	explode_hit_area.damage = explode_damage
	explode_hit_area.monitoring = false
	explode_hit_area.monitorable = false

	# Hide explode effect initially
	explode_effect.visible = false
	explode_effect.stop()

	# Duplicate shader material for this instance
	if animated_sprite_2d.material is ShaderMaterial:
		animated_sprite_2d.material = animated_sprite_2d.material.duplicate()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	# Check for player detection if not already exploding
	if not is_exploding:
		_check_player_proximity()

	# Handle explosion warning timer
	if is_exploding and warning_timer > 0:
		warning_timer -= delta
		if warning_timer <= 0:
			_explode()

func _check_player_proximity() -> void:
	if detect_front.is_colliding():
		var collider = detect_front.get_collider()
		if collider is Player:
			_start_explosion_warning()

func _start_explosion_warning() -> void:
	is_exploding = true
	warning_timer = explode_warning_time

	# Stop movement
	velocity = Vector2.ZERO

	# Start red blinking effect
	_start_blink_effect()

func _start_blink_effect() -> void:
	var mat := animated_sprite_2d.material as ShaderMaterial
	if mat == null:
		return

	mat.set_shader_parameter("flash_color", Color(1, 0.2, 0.2, 1))
	mat.set_shader_parameter("flash_amount", 0.0)

	if is_instance_valid(_flash_tw):
		_flash_tw.kill()

	_flash_tw = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var blink_count = 4
	var step := explode_warning_time / float(blink_count * 2)
	for i in blink_count:
		_flash_tw.tween_property(mat, "shader_parameter/flash_amount", 1.0, step)
		_flash_tw.tween_property(mat, "shader_parameter/flash_amount", 0.0, step)

func _explode() -> void:
	# Hide mushroom sprite (but keep collision for now)
	animated_sprite_2d.visible = false
	velocity = Vector2.ZERO

	# Reparent explosion effect to current scene so it doesn't move with mushroom
	var current_scene = get_tree().current_scene
	if explode_effect.get_parent():
		explode_effect.get_parent().remove_child(explode_effect)
	current_scene.add_child(explode_effect)
	explode_effect.global_position = global_position

	# Enable explosion hit area
	explode_hit_area.monitoring = true
	explode_hit_area.monitorable = true

	# Reparent explode hit area too
	if explode_hit_area.get_parent():
		explode_hit_area.get_parent().remove_child(explode_hit_area)
	current_scene.add_child(explode_hit_area)
	explode_hit_area.global_position = global_position

	# Show and play explode effect
	explode_effect.visible = true
	explode_effect.frame = 0
	explode_effect.play("default")

	# Connect to animation finished if not already connected
	if not explode_effect.animation_finished.is_connected(_on_explode_finished):
		explode_effect.animation_finished.connect(_on_explode_finished)

func _on_explode_finished() -> void:
	# Disable mushroom collision and explosion hit area after animation
	$CollisionShape2D.disabled = true
	explode_hit_area.monitoring = false
	explode_hit_area.monitorable = false

	# Clean up explosion effect and hit area (they were reparented)
	if is_instance_valid(explode_effect):
		explode_effect.queue_free()
	if is_instance_valid(explode_hit_area):
		explode_hit_area.queue_free()

	# Queue mushroom for deletion
	queue_free()
