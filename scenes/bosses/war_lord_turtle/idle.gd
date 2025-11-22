extends WarlordTurtleState

var idle_to_skill_delay: float = 2.75
var is_next_attack: bool = false          # toggle atk1 / atk2
var first_attack: bool = true

# Phase 2:
var is_followup_next: bool = false        # false: cast atk1/2, true: cast follow-up (atk3 / portal)
var is_next_followup_portal: bool = false # toggle giữa atk3 và summon_portal

func _enter() -> void:
	timer = idle_to_skill_delay
	obj.change_animation("idle")


func _update(delta: float) -> void:
	# Lần đầu thấy player thì đánh ngay, không chờ timer
	if obj.seen_player and first_attack:
		first_attack = false
		_decide_and_go_next_state()
		return

	if update_timer(delta):
		if not obj.seen_player:
			fsm.change_state(fsm.states.idle)
		else:
			_decide_and_go_next_state()


# ----------------- Helpers -----------------

func _decide_and_go_next_state() -> void:
	if obj.in_phase2:
		_run_phase2_pattern()
	else:
		_run_phase1_pattern()


# Phase 1: chỉ atk1 / atk2 như cũ
func _run_phase1_pattern() -> void:
	if not is_next_attack:
		is_next_attack = true
		fsm.change_state(fsm.states.atk_1)
	else:
		is_next_attack = false
		fsm.change_state(fsm.states.atk_2)


# Phase 2: atk1/2 <-> (atk3 hoặc portal) luân phiên
func _run_phase2_pattern() -> void:
	if not is_followup_next:
		# Lượt này: main attack (atk1 / atk2)
		is_followup_next = true

		if not is_next_attack:
			is_next_attack = true
			fsm.change_state(fsm.states.atk_1)
		else:
			is_next_attack = false
			fsm.change_state(fsm.states.atk_2)
	else:
		# Lượt này: follow-up (atk3 hoặc summon_portal)
		is_followup_next = false

		if is_next_followup_portal:
			# Lần này dùng portal
			is_next_followup_portal = false
			fsm.change_state(fsm.states.summon_portal)
		else:
			# Lần này dùng atk3
			is_next_followup_portal = true
			fsm.change_state(fsm.states.atk_3)
