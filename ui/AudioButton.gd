class_name AudioButton
extends Button


func _on_Button_pressed() -> void:
	$PressedAudio.play()
