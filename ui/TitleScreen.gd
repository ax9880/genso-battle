extends Control


onready var quit_button: Button = $MarginContainer/VBoxContainer2/VBoxContainer/QuitButton
onready var start_button: Button = $MarginContainer/VBoxContainer2/VBoxContainer/StartButton


func _ready():
	if OS.get_name() == "HTML5":
		quit_button.hide()
	
	start_button.grab_focus()
	
	var save_data: SaveData = GameData.save_data
	
	if save_data.current_battle_index > 0 or save_data.current_battle_scene_index > 0:
		start_button.text = tr("CONTINUE")


func _on_StartButton_pressed() -> void:
	var save_data: SaveData = GameData.save_data
	
	if save_data.current_battle_index == 0 and save_data.current_battle_scene_index == 0:
		var _error = get_tree().change_scene("res://battles/part_1/ScriptCutscenePart1.tscn")
	else:
		var _error = get_tree().change_scene("res://ui/PreBattleMenu.tscn")


func _on_ContinueButton_pressed() -> void:
	# TODO: Load data
	pass # Replace with function body.


func _on_SettingsButton_pressed() -> void:
	var _error = get_tree().change_scene("res://ui/SettingsMenu.tscn")


func _on_CreditsButton_pressed() -> void:
	var _error = get_tree().change_scene("res://ui/CreditsMenu.tscn")


func _on_QuitButton_pressed() -> void:
	get_tree().quit()
