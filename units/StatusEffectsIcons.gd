extends Control

var index: int = 0


func update_icon(status_effects: Array) -> void:
	if not status_effects.empty():
		if index >= status_effects.size():
			index = 0
		
		var status_effect: StatusEffect = status_effects[index]
		
		if status_effect.icon != null:
			$Icon.texture = status_effect.icon
		
		$AnimationPlayer.play("show icon and fade")
