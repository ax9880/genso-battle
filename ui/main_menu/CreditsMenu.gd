extends StackBasedMenuScreen


onready var _return_button: Button = $MarginContainer/VBoxContainer/ReturnButton


func on_load() -> void:
	.on_load()
	
	_return_button.grab_focus()


func _on_ReturnButton_pressed() -> void:
	go_back()
