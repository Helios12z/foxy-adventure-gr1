extends BaseCharacter


@export var player_path: NodePath
@onready var player: Node2D = get_node_or_null(player_path)
@onready var sprite: AnimatedSprite2D = $Direction/AnimatedSprite2D

var anchors: Array[Node2D] = []
@export var anchor_move_time := 0.5

@export var eruption_duration := 1.5

func _ready() -> void:
	gravity = 0
	super._ready()

	await get_tree().process_frame
	_init_anchors_from_room()

	fsm = FSM.new(self, $States, $States/Phase1)


func _physics_process(delta: float) -> void:
	if fsm != null:
		fsm._update(delta)

	if player:
		var dx := player.global_position.x - global_position.x
		if abs(dx) > 1.0:
			sprite.flip_h = dx < 0


func _init_anchors_from_room() -> void:
	anchors.clear()

	var nodes := get_tree().get_nodes_in_group("BossAnchor")
	if nodes.is_empty():
		push_error("Boss3: Khong tim thay BossAnchor nao trong room")
		return

	# sort theo export var index trong BossAnchor.gd
	nodes.sort_custom(func(a, b):
		var ia = a.index   # yêu cầu BossAnchor.gd nào cũng có @export var index
		var ib = b.index
		return ia < ib
	)

	for n in nodes:
		anchors.append(n)

	if anchors.size() < 5:
		push_warning("Boss3: anchors.size() = %d (<5), kiem tra room" % anchors.size())



func move_to_anchor(index: int) -> void:
	if anchors.is_empty():
		push_error("Boss3: anchors rong, quen config BossAnchor trong room")
		return

	index = clamp(index, 0, anchors.size() - 1)
	var target := anchors[index].global_position

	if global_position == target:
		return

	var tween := create_tween()
	tween.tween_property(self, "global_position", target, anchor_move_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	await tween.finished

# Optional: helper log cho gọn
func _log_skill(name: String, phase: String) -> void:
	print("[Boss3] ", name, " - ", phase)

# ===========================
# SKILL 1: WATER ERUPTION WAVE (anchor 1 - center high)
# ===========================
func do_eruption_wave() -> void:
	_log_skill("EruptionWave", "MOVE_TO_ANCHOR_1")
	await move_to_anchor(1) # CenterHigh

	# TELEGRAPH
	_log_skill("EruptionWave", "TELEGRAPH_START")
	sprite.play("cast_eruption")
	await get_tree().create_timer(0.6).timeout
	_log_skill("EruptionWave", "TELEGRAPH_END")

	# ACTIVE - gọi tất cả WaterEruption
	_log_skill("EruptionWave", "ACTIVE_START")
	for w in get_tree().get_nodes_in_group("WaterEruption"):
		if w.has_method("play"):
			w.play()
	await get_tree().create_timer(0.4).timeout
	_log_skill("EruptionWave", "ACTIVE_END")

	# RECOVERY
	_log_skill("EruptionWave", "RECOVERY_START")
	sprite.play("recover")
	await get_tree().create_timer(0.5).timeout
	_log_skill("EruptionWave", "RECOVERY_END")


# ===========================
# SKILL 2: WATER PAGODA (anchor 0 - left high)
# ===========================
func do_water_pagoda() -> void:
	_log_skill("WaterPagoda", "MOVE_TO_ANCHOR_0")
	await move_to_anchor(0) # LeftHigh

	# TELEGRAPH
	_log_skill("WaterPagoda", "TELEGRAPH_START")
	sprite.play("cast_pagoda")
	await get_tree().create_timer(0.7).timeout
	_log_skill("WaterPagoda", "TELEGRAPH_END")

	# ACTIVE - tháp nước
	_log_skill("WaterPagoda", "ACTIVE_START")
	for w in get_tree().get_nodes_in_group("WaterPagoda"):
		if w.has_method("play"):
			w.play()
	await get_tree().create_timer(0.6).timeout
	_log_skill("WaterPagoda", "ACTIVE_END")

	# RECOVERY
	_log_skill("WaterPagoda", "RECOVERY_START")
	sprite.play("recover")
	await get_tree().create_timer(0.5).timeout
	_log_skill("WaterPagoda", "RECOVERY_END")


# ===========================
# SKILL 3: WATER PILLAR (anchor 3 - left low)
# Trụ nước trồi ngay vị trí player / gần player
# ===========================
func do_water_pillar() -> void:
	_log_skill("WaterPillar", "MOVE_TO_ANCHOR_3")
	await move_to_anchor(3) # LeftLow (gần chiều cao player hơn)

	# TELEGRAPH: boss nhìn xuống, vòng nước dưới chân player
	_log_skill("WaterPillar", "TELEGRAPH_START")
	sprite.play("cast_pillar")
	# TODO: spawn hiệu ứng telegraph tại vị trí player hiện tại
	#       ví dụ: spawn 1 node "PillarTelegraph" ở player.global_position
	await get_tree().create_timer(0.5).timeout
	_log_skill("WaterPillar", "TELEGRAPH_END")

	# ACTIVE: trụ nước trồi lên
	_log_skill("WaterPillar", "ACTIVE_START")
	# TODO: spawn / kích hoạt WaterPillar thật sự (hitbox)
	#       có thể dùng 1 scene riêng lấy target_pos là nơi đã telegraph
	for w in get_tree().get_nodes_in_group("WaterPillar"):
		if w.has_method("play"):
			w.play()
	await get_tree().create_timer(0.3).timeout
	_log_skill("WaterPillar", "ACTIVE_END")

	# RECOVERY
	_log_skill("WaterPillar", "RECOVERY_START")
	sprite.play("recover")
	await get_tree().create_timer(0.5).timeout
	_log_skill("WaterPillar", "RECOVERY_END")


# ===========================
# SKILL 4: VASE WATER (anchor 2 - right high)
# Boss rải bình nước setup dưới đất
# ===========================
func do_vase_water() -> void:
	_log_skill("VaseWater", "MOVE_TO_ANCHOR_2")
	await move_to_anchor(2) # RightHigh

	# TELEGRAPH: boss tụ nước, bình hiện "ghost" trước khi thật sự spawn
	_log_skill("VaseWater", "TELEGRAPH_START")
	sprite.play("cast_vase")
	await get_tree().create_timer(0.6).timeout
	_log_skill("VaseWater", "TELEGRAPH_END")

	# ACTIVE: spawn bình / kích hoạt group
	_log_skill("VaseWater", "ACTIVE_START")
	# TODO:
	#   - spawn vài "vase" rơi xuống dưới
	#   - hoặc kích hoạt các scene trong group "VaseWater"
	for w in get_tree().get_nodes_in_group("VaseWater"):
		if w.has_method("play"):
			w.play()
	await get_tree().create_timer(0.4).timeout
	_log_skill("VaseWater", "ACTIVE_END")

	# RECOVERY: cửa player lên chém
	_log_skill("VaseWater", "RECOVERY_START")
	sprite.play("recover")
	await get_tree().create_timer(0.6).timeout
	_log_skill("VaseWater", "RECOVERY_END")


# ===========================
# SKILL 5: WATER BALL (anchor 4 - right low)
# Boss bắn cầu nước truy đuổi / hướng player
# ===========================
func do_water_ball() -> void:
	_log_skill("WaterBall", "MOVE_TO_ANCHOR_4")
	await move_to_anchor(4) # RightLow

	# TELEGRAPH: tụ quả cầu nước trong tay
	_log_skill("WaterBall", "TELEGRAPH_START")
	sprite.play("cast_ball")
	await get_tree().create_timer(0.4).timeout
	_log_skill("WaterBall", "TELEGRAPH_END")

	# ACTIVE: bắn projectile
	_log_skill("WaterBall", "ACTIVE_START")
	# TODO:
	#   - spawn 1–3 projectile, hướng về player.global_position
	#   - hoặc dùng group "WaterBall" để trigger các node sẵn có
	for w in get_tree().get_nodes_in_group("WaterBall"):
		if w.has_method("fire"):
			w.fire(player)          # nếu bạn thiết kế như vậy
		elif w.has_method("play"):
			w.play()                # fallback
	await get_tree().create_timer(0.5).timeout
	_log_skill("WaterBall", "ACTIVE_END")

	# RECOVERY: ngắn hơn để phase 2 nhanh hơn
	_log_skill("WaterBall", "RECOVERY_START")
	sprite.play("recover")
	await get_tree().create_timer(0.4).timeout
	_log_skill("WaterBall", "RECOVERY_END")
