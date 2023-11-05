extends StackBasedMenuScreen


onready var return_button: Button = $MarginContainer/VBoxContainer/ReturnButton


func on_load() -> void:
	return_button.grab_focus()


func _on_ReturnButton_pressed() -> void:
	go_back()


func _on_VolumeSlider_on_changed(bus_name: String, volume: float) -> void:
	# TODO: Save volume in configs
	
	pass
