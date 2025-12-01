extends Area2D
# Damage gây lên HurtArea2D (enemy)
@export var damage: int = 1
# Scene sử dụng để spawn fire hole
@export var fire_hole_scene_path: String = "res://scenes/skills/susanoo/fire_hole.tscn"
# Thời gian hồi giữa các lần spawn hole để tránh spam
@export var spawn_cooldown: float = 0.08
var _last_spawn_time: float = -9999.0
func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
# Gây damage lên Area2D có phương thức take_damage (HurtArea2D)
func _on_area_entered(area: Area2D) -> void:
	if area and area.has_method("take_damage"):
		var hit_dir: Vector2 = area.global_position - global_position
		var dmg := _get_susanoo_damage()
		area.take_damage(hit_dir.normalized(), dmg)
		# Sau khi gây damage lên enemy, làm fireball biến mất
		_vanish_fireball()
# Khi chạm body (platform), không tự spawn hole để tránh trùng với RayCast trong fire_ball.gd
func _on_body_entered(body: Node) -> void:
	pass
# Việc spawn hole sẽ do fire_ball.gd thực hiện bằng RayCast (chính xác bề mặt)
func _vanish_fireball() -> void:
	# Tìm node cha có phương thức vanish (Path2D của FireBall)
	var node: Node = self
	while node != null:
		if node.has_method("vanish"):
			node.call_deferred("vanish")
			return
		node = node.get_parent()
func _is_platform(body: Node) -> bool:
	if body == null:
		return false
	if body.has_method("is_in_group") and body.is_in_group("platform"):
		return true
	var name_str := String(body.name).to_lower()
	return name_str.find("platform") != -1

func _get_susanoo_damage() -> int:
	var p := GameManager.player if Engine.has_singleton("GameManager") else null
	if p == null:
		p = get_tree().get_first_node_in_group("Player")
	if p and p.has_node("Direction/HitArea2D"):
		var ha := p.get_node("Direction/HitArea2D")
		if ha:
			var base := int(ha.get("damage"))
			return max(1, base * 2)
	return max(1, damage)
