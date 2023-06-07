extends Node2D


onready var tween: Tween = $Tween
onready var label: Label = $Label
onready var target_position: Position2D = $Position2D

export(Color) var heal_color: Color

export(float) var float_duration_seconds: float = 0.65


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
				Vector2.ZERO, scale,
				float_duration_seconds * 0.5,
				Tween.TRANS_BACK,
				Tween.EASE_OUT)
	
	_error = tween.interpolate_property(self, "modulate",
				label.modulate, Color.transparent,
				float_duration_seconds * 0.95,
				Tween.TRANS_LINEAR)
	
	_error = tween.start()


func _on_Tween_tween_all_completed() -> void:
	queue_free()
