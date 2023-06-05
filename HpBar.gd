extends TextureProgress


onready var tween: Tween = $Tween


func _on_Job_health_changed(current_health: int, max_health: int) -> void:
	tween.remove(self, ":scale")
	
	var next_value: int = max_value * current_health / max_health
	
	tween.interpolate_property(self, "value",
		value, next_value,
		0.25,
		Tween.TRANS_LINEAR)
	
	tween.start()
