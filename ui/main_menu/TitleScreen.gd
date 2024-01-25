extends StackBasedMenuScreen

export(String, FILE, "*.tscn") var settings_scene: String
export(String, FILE, "*.tscn") var credits_scene: String


onready var quit_button: Button = $MarginContainer/VBoxContainer2/VBoxContainer/QuitButton
onready var start_button: Button = $MarginContainer/VBoxContainer2/VBoxContainer/StartButton


var last_active_button: Button = null


func _ready() -> void:
	if OS.get_name() == "HTML5":
		quit_button.hide()
	
	_set_focus()
	
	# TODO: Show continue text if there is valid save data


func on_load() -> void:
	.on_load()
	
	_set_focus()


func _set_focus() -> void:
	if last_active_button != null:
		last_active_button.grab_focus()
	else:
		start_button.grab_focus()
		
		last_active_button = start_button


func _on_StartButton_pressed() -> void:
	change_scene("res://ui/pre_battle_menu/StackBasedPreBattleMenu.tscn")


func _on_ContinueButton_pressed() -> void:
	# TODO: Load data
	pass # Replace with function body.


func _on_SettingsButton_pressed() -> void:
	last_active_button = $MarginContainer/VBoxContainer2/VBoxContainer/SettingsButton
	
	navigate(settings_scene)


func _on_CreditsButton_pressed() -> void:
	last_active_button = $MarginContainer/VBoxContainer2/VBoxContainer/CreditsButton
	
	navigate(credits_scene)


func _on_QuitButton_pressed() -> void:
	get_tree().quit()


func _on_TitleScreen_tree_entered() -> void:
	TranslationServer.set_locale(TranslationServer.get_locale())
