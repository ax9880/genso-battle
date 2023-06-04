extends Node2D


onready var tween: Tween = $Tween
onready var label_container: Node2D = $LabelContainer
onready var target_position: Position2D = $Position2D

export(float) var float_duration_seconds: float = 0.5


var random: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	random.randomize()
	
	$AnimatedSprite.frame = 0
	$AnimatedSprite.play("default")
	$AnimatedSprite.rotation_degrees = random.randf_range(0, 360)
	
	var _error = tween.interpolate_property(label_container, "position",
				label_container.position, target_position.position,
				float_duration_seconds,
				Tween.TRANS_LINEAR)
			
	_error = tween.interpolate_property(self, "modulate",
				label_container.modulate, Color.transparent,
				float_duration_seconds * 0.75,
				Tween.TRANS_LINEAR)
			
	_error = tween.start()


func set_value(value: int) -> void:
	$LabelContainer/Label.text = str(value)


func _on_Tween_tween_all_completed() -> void:
	queue_free()
