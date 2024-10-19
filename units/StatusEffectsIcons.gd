extends Control


var _index: int = 0


func update_icon(status_effects: Array) -> void:
	if not status_effects.empty():
		if _index >= status_effects.size():
			_index = 0
		
		var status_effect: StatusEffect = status_effects[_index]
		
		assert(status_effect.icon != null)
		
		if status_effect.icon != null:
			$Icon.texture = status_effect.icon
		
		$AnimationPlayer.stop()
		$AnimationPlayer.play("show icon and fade")
		
		_index += 1
