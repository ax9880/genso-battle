extends Control


onready var return_button: Button = $MarginContainer/VBoxContainer/ReturnButton


func _ready() -> void:
	return_button.grab_focus()


func _on_ReturnButton_pressed() -> void:
	get_tree().change_scene("res://ui/TitleScreen.tscn")
