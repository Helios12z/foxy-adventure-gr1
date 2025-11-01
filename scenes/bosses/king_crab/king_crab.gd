extends EnemyCharacter

@export var move_speed: float = 350.0
@export var attack_range: float = 700.0
@export var arena_min_x: float = -9999.0
@export var arena_max_x: float = 9999.0
@export var fatigue_after_atk2: float = 2.0
@export var claw_scene: PackedScene
@export var roll_speed: float = 280.0   # dùng bởi control_roll()

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# --- Luân phiên skill ---
var next_attack_is_claw: bool = true  # Walk.gd dùng tên này

# --- Trạng thái “càng rời” ---
var has_claw: bool = true
var current_claw: Node2D = null
var claw_origin: Vector2 = Vector2.ZERO
var claw_target: Vector2 = Vector2.ZERO
var claw_phase_out: bool = true   # true: đang bay ra; false: bay về

func _ready() -> void:
	# Base init (raycasts, detect area, hurt area)
	super._ready()

	# Đồng bộ tốc độ cho control_walk()
	movement_speed = move_speed

	# Bật vùng phát hiện player (để found_player != null khi vào phạm vi)
	enable_check_player_in_sight()

	# Khởi tạo FSM với state đầu là Walk
	fsm = FSM.new(self, $States, $States/Walk)

func _physics_process(delta: float) -> void:
	# Base physics
	super._physics_process(delta)

	# Cập nhật FSM mỗi frame (QUAN TRỌNG)
	if fsm != null:
		fsm._update(delta)

	# Không cho vượt biên đấu trường
	clamp_to_arena()

# ===== Helpers / API được state gọi (không xoay sprite) =====

func clamp_to_arena() -> void:
	global_position.x = clamp(global_position.x, arena_min_x, arena_max_x)

func can_attack1() -> bool:
	# ATK1 = bắn càng: có player và trong tầm
	if found_player == null:
		return false
	var dist: float = absf(found_player.global_position.x - global_position.x)
	return has_claw and (dist <= attack_range * 0.9)

func can_attack2() -> bool:
	# ATK2 = lăn: chỉ cần thấy player
	return found_player != null

# Hooks cho “càng” (gọi từ script claw/bullet)
func on_claw_launched(origin: Vector2) -> void:
	has_claw = false
	claw_phase_out = true
	claw_origin = origin

func on_claw_returned() -> void:
	has_claw = true
	current_claw = null
	claw_phase_out = false

# Khi nhìn thấy player → quay đầu bằng hệ Direction trong BaseCharacter
func _on_player_in_sight(player_pos: Vector2) -> void:
	var need_dir: int = 1
	if player_pos.x < global_position.x:
		need_dir = -1
	if need_dir != direction:
		change_direction(need_dir)
		_check_changed_direction()

# ================= KingCrab-only controls (NO sprite flip) =================

# Tiến tới một toạ độ X: di chuyển theo physics (velocity + move_and_slide)
func control_move_towards_x(target_x: float, speed: float, delta: float, snap: bool = true) -> bool:
	var dir_to_target: int = 1
	if target_x < global_position.x:
		dir_to_target = -1

	if dir_to_target != direction:
		change_direction(dir_to_target)
		_check_changed_direction()

	velocity.x = direction * speed
	move_and_slide()

	# clamp biên
	if global_position.x < arena_min_x:
		global_position.x = arena_min_x
	if global_position.x > arena_max_x:
		global_position.x = arena_max_x

	var reached: bool = false
	if direction > 0 and global_position.x >= target_x:
		reached = true
	elif direction < 0 and global_position.x <= target_x:
		reached = true

	if reached and snap:
		global_position.x = target_x

	return reached

# Quay đầu nhìn về một toạ độ X (dùng Direction)
func control_face_towards_x(x: float) -> void:
	var need_dir: int = 1
	if x < global_position.x:
		need_dir = -1
	if need_dir != direction:
		change_direction(need_dir)
		_check_changed_direction()

# Spawn càng (node bullet) ra world
func control_spawn_claw(spawn_pos: Vector2) -> Node2D:
	var ps: PackedScene = claw_scene
	if ps == null:
		ps = load("res://scenes/bosses/king_crab/king_crab_bullet.tscn")

	var claw: Node2D = ps.instantiate()
	claw.global_position = spawn_pos

	var root := get_tree().current_scene
	if root == null:
		add_child(claw)
	else:
		root.add_child(claw)

	return claw

# Điều khiển càng bay ra → bay về. Trả true khi đã về và thu hồi xong
func control_claw_out_and_back(delta: float) -> bool:
	if current_claw == null:
		return true
	if not is_instance_valid(current_claw):
		return true

	var speed: float = move_speed
	var target: Vector2 = claw_target
	if not claw_phase_out:
		target = claw_origin

	var claw := current_claw as Node2D
	var to_target: Vector2 = target - claw.global_position
	var step_len: float = speed * delta

	if to_target.length() <= step_len:
		claw.global_position = target
		if claw_phase_out:
			claw_phase_out = false
		else:
			claw.queue_free()
			current_claw = null
			return true
	else:
		var dir_vec: Vector2 = to_target.normalized()
		claw.global_position += dir_vec * step_len

	return false

# Lăn theo direction hiện tại, chạm biên trả true
func control_roll(delta: float, to_left_limit: float, to_right_limit: float) -> bool:
	velocity.x = direction * roll_speed
	move_and_slide()

	var x := global_position.x
	if direction < 0 and x <= to_left_limit:
		return true
	if direction > 0 and x >= to_right_limit:
		return true
	return false

# Chọn biên dựa theo direction hiện tại
func roll_target_x() -> float:
	if direction > 0:
		return arena_max_x
	return arena_min_x
