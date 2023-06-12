extends Control


signal try_again_button_pressed
signal quit_button_pressed


func _on_TryAgainButton_pressed() -> void:
	emit_signal("try_again_button_pressed")


func _on_QuitButton_pressed() -> void:
	emit_signal("quit_button_pressed")
