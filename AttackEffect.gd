extends AnimatedSprite

export(float) var float_duration_seconds: float = 0.65

var random: RandomNumberGenerator = RandomNumberGenerator.new()


# TODO: Unique animation per weapon type
func _ready() -> void:
	random.randomize()
	
	frame = 0
	play("default")
	rotation_degrees = random.randf_range(0, 360)
	
	if random.randf() < 0.5:
		flip_h = true


func _on_AttackEffect_animation_finished():
	queue_free()
