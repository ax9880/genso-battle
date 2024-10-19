extends StackBasedMenuScreen


export(String, FILE, "*.tscn") var settings_scene: String
export(String, FILE, "*.tscn") var credits_scene: String

var _last_active_button: Button = null

onready var _quit_button: Button = $MarginContainer/VBoxContainer2/VBoxContainer/QuitButton
onready var _start_button: Button = $MarginContainer/VBoxContainer2/VBoxContainer/StartButton


func _ready() -> void:
	if OS.get_name() == "HTML5":
		_quit_button.hide()
	
	_set_focus()
	
	# TODO: Show continue text if there is valid save data


func on_load() -> void:
	.on_load()
	
	_set_focus()


func _set_focus() -> void:
	if _last_active_button != null:
		_last_active_button.grab_focus()
	else:
		_start_button.grab_focus()
		
		_last_active_button = _start_button


func _on_StartButton_pressed() -> void:
	change_scene("res://ui/pre_battle_menu/stack_based_pre_battle_menu.tscn")


func _on_ContinueButton_pressed() -> void:
	# TODO: Load data
	pass # Replace with function body.


func _on_SettingsButton_pressed() -> void:
	_last_active_button = $MarginContainer/VBoxContainer2/VBoxContainer/SettingsButton
	
	navigate(settings_scene)


func _on_CreditsButton_pressed() -> void:
	_last_active_button = $MarginContainer/VBoxContainer2/VBoxContainer/CreditsButton
	
	navigate(credits_scene)


func _on_QuitButton_pressed() -> void:
	get_tree().quit()


func _on_TitleScreen_tree_entered() -> void:
	TranslationServer.set_locale(TranslationServer.get_locale())
