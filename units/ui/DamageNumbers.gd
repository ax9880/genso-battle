extends Node2D


export(Color) var heal_color: Color

onready var _label: Label = $Label


func play(value: int) -> void:
	if value == 0:
		hide()
		
		queue_free()
	else:
		if value < 0:
			_label.modulate = heal_color
		
		_label.text = str(abs(value))
		
		$AnimationPlayer.play("Appear and then disappear")
