extends Control


signal continue_button_pressed


func initialize(total_drag_time_seconds: float, player_turn_count: int) -> void:
	var formatted_drag_time_string: String = tr("TOTAL_DRAG_TIME").format({"time": "%0.1f" % total_drag_time_seconds})
	
	$MarginContainer/VBoxContainer/DragTimeLabel.text = formatted_drag_time_string
	
	var formatted_turn_count_string: String = tr("TURN_COUNT").format({"count": player_turn_count})
	
	$MarginContainer/VBoxContainer/TurnCountLabel.text = formatted_turn_count_string


func _on_ContinueButton_pressed() -> void:
	emit_signal("continue_button_pressed")


func _on_VictoryScreen_visibility_changed() -> void:
	$CPUParticles2D.emitting = visible
