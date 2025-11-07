extends Node2D

@export var ball_delay_step: float = 0.15
@export var ball_delay_rand_max: float = 0.20
@export var circle_disappear_delay: float = 4.0
@export var max_skill_duration: float = 8.0

var _circle: Node
var _balls_parent: Node
var _balls: Array[Node] = []
var _appear_count: int = 0
var _circle_disappear_scheduled: bool = false
var _accounted_count: int = 0

func _ready() -> void:
	_circle = get_node_or_null("FireCircle")
	_balls_parent = get_node_or_null("FireBalls")
	if _balls_parent:
		for child in _balls_parent.get_children():
			_balls.append(child)

func start() -> void:
	# Circle appears and scales up smoothly
	if _circle and _circle.has_method("appear"):
		_circle.call("appear")
	# Stagger fireballs
	_appear_count = 0
	_accounted_count = 0
	var idx := 0
	for ball in _balls:
		if ball and ball.has_method("start"):
			var delay := idx * ball_delay_step + randf() * ball_delay_rand_max
			ball.call("start", delay)
			if ball.has_signal("appeared"):
				ball.connect("appeared", Callable(self, "_on_ball_appeared"))
			# Đếm cả trường hợp bóng biến mất sớm để đảm bảo FireCircle biến mất ổn định
			if ball.has_signal("vanished"):
				ball.connect("vanished", Callable(self, "_on_ball_accounted"))
		idx += 1

	# Fallback: nếu vì lý do nào đó không đủ tín hiệu, vẫn đảm bảo vòng tròn biến mất
	_start_failsafe_timer()

func _on_ball_appeared() -> void:
	_appear_count += 1
	if _appear_count >= _balls.size():
		# When all balls have appeared, schedule circle to disappear after delay
		if not _circle_disappear_scheduled:
			_circle_disappear_scheduled = true
			_schedule_circle_disappear()

func _on_ball_accounted() -> void:
	_accounted_count += 1
	if _accounted_count >= _balls.size():
		# Nếu có bóng biến mất sớm (không emit appeared), vẫn đảm bảo vòng tròn biến mất
		if not _circle_disappear_scheduled:
			_circle_disappear_scheduled = true
			_schedule_circle_disappear()

func _schedule_circle_disappear() -> void:
	if _circle and _circle.has_method("disappear"):
		await get_tree().create_timer(max(circle_disappear_delay, 0.0)).timeout
		_circle.call("disappear")

func _start_failsafe_timer() -> void:
	await get_tree().create_timer(max(max_skill_duration, 0.0)).timeout
	if not _circle_disappear_scheduled:
		_circle_disappear_scheduled = true
		_schedule_circle_disappear()
