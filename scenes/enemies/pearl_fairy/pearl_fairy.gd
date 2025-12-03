extends EnemyCharacter

@export var bob_amplitude: float = 6.0
@export var bob_speed: float = 2.0

var _base_dir_y: float = 0.0
var _bob_t: float = 0.0

var attack_immediately_next_move: bool = false
var attack_cooldown_timer: float = 0.0

@onready var dir_node: Node2D = $Direction
@onready var marker: Marker2D = $Direction/MoveMarker2D

var initial_marker_pos: Vector2

func _ready() -> void:
	gravity = 0.0
	initial_marker_pos = marker.global_position
	_base_dir_y = dir_node.position.y
	super._ready()
	fsm = FSM.new(self, $States, $States/Idle)

func _process(delta: float) -> void:
	_bob_t += delta * bob_speed
	dir_node.position.y = _base_dir_y + sin(_bob_t) * bob_amplitude
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta
		if attack_cooldown_timer < 0.0:
			attack_cooldown_timer = 0.0

func _on_player_in_sight(_player_pos: Vector2):
	if health <= 0:
		return
	if fsm != null and fsm.current_state == fsm.states.dead:
		return
	attack_immediately_next_move = true
	if fsm != null and fsm.states.has("move"):
		fsm.change_state(fsm.states.move)

func _on_player_not_in_sight():
	if health <= 0:
		return
	if fsm != null and fsm.current_state == fsm.states.dead:
		return
	attack_immediately_next_move = false
	if fsm != null and fsm.states.has("idle"):
		fsm.change_state(fsm.states.idle)

func _on_changed_direction() -> void:
	# Flip điểm spawn đạn theo hướng mặt
	if has_node("Node2DFactory"):
		var f: Node2D = $Node2DFactory
		var px = abs(f.position.x)
		f.position.x = px * (1 if direction == 1 else -1)
