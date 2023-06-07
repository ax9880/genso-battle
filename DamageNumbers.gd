extends Node2D


onready var tween: Tween = $Tween
onready var label: Label = $Label
onready var target_position: Position2D = $Position2D

export(Color) var heal_color: Color

export(float) var float_duration_seconds: float = 1


func play(value: int) -> void:
	if value == 0:
		hide()
		queue_free()
		
		return
	
	if value < 0:
		label.modulate = heal_color
	
	label.text = str(abs(value))
	
	var _error = tween.interpolate_property(self, "position",
				self.position, self.position + target_position.position,
				float_duration_seconds,
				Tween.TRANS_LINEAR)
	
	_error = tween.interpolate_property(self, "scale",
				Vector2(0.3, 0.3), scale,
				float_duration_seconds * 0.4,
				Tween.TRANS_SINE,
				Tween.EASE_OUT)
	
	_error = tween.start()


func _on_Tween_tween_all_completed() -> void:
	queue_free()


func _on_Tween_tween_completed(_object: Object, key: String) -> void:
	if key == ":scale":
		var _error = tween.interpolate_property(self, "modulate",
					label.modulate, Color.transparent,
					float_duration_seconds * 0.2,
					Tween.TRANS_LINEAR)
		
		_error = tween.start()
