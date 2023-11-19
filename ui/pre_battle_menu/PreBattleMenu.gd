extends StackBasedMenuScreen


export(PackedScene) var battle_button_packed_scene: PackedScene


func _ready() -> void:
	_create_buttons_for_unlocked_battles()
	
	_set_focus()


func on_load() -> void:
	.on_load()
	
	_set_focus()


func _set_focus() -> void:
	$MarginContainer/VBoxContainer/HBoxContainer/SquadButton.grab_focus()


func _create_buttons_for_unlocked_battles() -> void:
	for child in $MarginContainer/VBoxContainer/VBoxContainer2.get_children():
		child.queue_free()
	
	var save_data: SaveData = GameData.save_data
	
	var unlocked_battles = save_data.unlocked_battles
	
	for unlocked_battle in save_data.unlocked_battles:
		var button: Button = battle_button_packed_scene.instance()
		
		button.text = tr(unlocked_battle.title)
		
		button.connect("pressed", self, "on_BattleButton_pressed", [unlocked_battle])
		
		$MarginContainer/VBoxContainer/VBoxContainer2.add_child(button)


func _on_SquadButton_pressed() -> void:
	navigate("res://ui/pre_battle_menu/SquadMenu.tscn")


func _on_QuitButton_pressed() -> void:
	change_scene("res://ui/main_menu/StackBasedMainMenu.tscn")


func on_BattleButton_pressed(unlocked_battle: UnlockedBattle) -> void:
	var current_scene_path: String = unlocked_battle.current_scene
	
	if current_scene_path == null:
		# TODO: Get path from constants or resource
		pass
	
	change_scene(current_scene_path)
