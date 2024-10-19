extends AnimatedSprite

export(float) var float_duration_seconds: float = 0.65

var _random: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_random.randomize()
	
	frame = 0
	play("default")
	rotation_degrees = _random.randf_range(0, 360)
	
	if _random.randf() < 0.5:
		flip_h = true


func _on_AttackEffect_animation_finished() -> void:
	queue_free()
