extends Control



func _ready():
	# TODO: Create buttons that take you to each battle
	pass # Replace with function body.


func _on_SquadButton_pressed() -> void:
	var _error = get_tree().change_scene("res://ui/SquadMenu.tscn")


func _on_QuitButton_pressed() -> void:
	var _error = get_tree().change_scene("res://ui/TitleScreen.tscn")


func _on_Button_pressed():
	get_tree().change_scene("res://battles/part_1/Battle1.tscn")


func _on_TutorialButton_pressed():
	get_tree().change_scene("res://battles/Tutorial.tscn")
