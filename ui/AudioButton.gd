extends Button

class_name AudioButton


func _on_Button_pressed() -> void:
	$PressedAudio.play()
