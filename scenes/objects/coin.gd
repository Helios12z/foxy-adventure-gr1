extends Area2D

func _ready():
	$AnimatedSprite2D.play("appearance")
	body_entered.connect(_on_body_entered)
	$AnimatedSprite2D.animation_finished.connect(_on_coin_disappear_finished)
	
func _on_body_entered(body: Player):
	$Coin.play()
	$AnimatedSprite2D.play("disappearance")
	$AnimatedSprite2D.animation_finished

func _on_coin_disappear_finished():
	queue_free()
