extends TextureProgress


onready var _tween: Tween = $Tween


func _on_Job_health_changed(current_health: int, max_health: int) -> void:
	var _is_present = _tween.remove(self, ":scale")
	
	var next_value: int = int(max_value * current_health / max_health)
	
	var _error = _tween.interpolate_property(self, "value",
			value, next_value,
			0.25,
			Tween.TRANS_LINEAR)
	
	_error = _tween.start()
