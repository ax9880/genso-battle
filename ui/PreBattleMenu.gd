extends StackBasedMenuScreen


func _ready() -> void:
	# TODO: Create buttons that take you to each battle
	
	_set_focus()


func on_load() -> void:
	.on_load()
	
	_set_focus()


func _set_focus() -> void:
	$MarginContainer/VBoxContainer/HBoxContainer/SquadButton.grab_focus()


func _on_SquadButton_pressed() -> void:
	navigate("res://ui/pre_battle_menu/SquadMenu.tscn")


func _on_QuitButton_pressed() -> void:
	change_scene("res://ui/main_menu/StackBasedMainMenu.tscn")


func _on_Button_pressed() -> void:
	change_scene("res://battles/part_1/Battle1.tscn")


func _on_TutorialButton_pressed() -> void:
	change_scene("res://battles/Tutorial.tscn")
