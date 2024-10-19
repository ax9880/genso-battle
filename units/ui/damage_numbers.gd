extends Node2D


onready var label: Label = $Label

export(Color) var heal_color: Color


func play(value: int) -> void:
	if value == 0:
		hide()
		
		queue_free()
	else:
		if value < 0:
			label.modulate = heal_color
		
		label.text = str(abs(value))
		
		$AnimationPlayer.play("Appear and then disappear")
