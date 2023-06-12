extends Control


onready var quit_button: Button = $MarginContainer/VBoxContainer2/VBoxContainer/QuitButton
onready var start_button: Button = $MarginContainer/VBoxContainer2/VBoxContainer/StartButton


# Called when the node enters the scene tree for the first time.
func _ready():
	if OS.get_name() == "HTML5":
		quit_button.hide()
	
	start_button.grab_focus()


func _on_StartButton_pressed() -> void:
	var _error = get_tree().change_scene("res://ui/ScriptCutscene.tscn")


func _on_ContinueButton_pressed() -> void:
	# TODO: Load data
	pass # Replace with function body.


func _on_SettingsButton_pressed() -> void:
	var _error = get_tree().change_scene("res://ui/SettingsMenu.tscn")


func _on_CreditsButton_pressed() -> void:
	var _error = get_tree().change_scene("res://ui/CreditsMenu.tscn")


func _on_QuitButton_pressed() -> void:
	get_tree().quit()
