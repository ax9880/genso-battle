extends Control


onready var return_button: Button = $MarginContainer/VBoxContainer/ReturnButton


func _ready() -> void:
	return_button.grab_focus()


func _on_ReturnButton_pressed() -> void:
	var _error = get_tree().change_scene("res://ui/TitleScreen.tscn")


func _on_VolumeSlider_on_changed(bus_name: String, volume: float) -> void:
	# TODO: Save volume in configs
	
	pass
