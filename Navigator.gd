extends Node

# Array<BattleScenes>
export(Array, Resource) var battles: Array = []


func go_to_next() -> void:
	var save_data: SaveData = GameData.save_data
	
	var current_battle_index: int = save_data.current_battle_index
	
	# Battle index beyond amount of battles is invalid
	if current_battle_index > battles.size():
		get_tree().change_scene("res://ui/TitleScreen.tscn")
		
		_reset_values_and_return_to_title_screen(save_data)
	else:
		var current_battle: BattleScenes = battles[current_battle_index]
		
		save_data.current_battle_scene_index += 1
		
		if save_data.current_battle_scene_index == current_battle.scenes.size():
			# TODO: go to next battle
			pass
		elif save_data.current_battle_scene_index > current_battle.scenes.size():
			_reset_values_and_return_to_title_screen(save_data)
		else:
			var error = get_tree().change_scene(current_battle.scenes[save_data.current_battle_scene_index])
			
			if error != OK:
				_reset_values_and_return_to_title_screen(save_data)


func go_to_current() -> void:
	var save_data: SaveData = GameData.save_data
	
	var current_battle_index: int = save_data.current_battle_index
	
	assert(current_battle_index < battles.size())
	
	var current_battle: BattleScenes = battles[current_battle_index]
	
	assert(save_data.current_battle_scene_index < current_battle.battles.size())
	
	var current_scene_path: String = current_battle.battles[save_data.current_battle_scene_index]
	
	if get_tree().change_scene(current_scene_path) != OK:
		printerr("Failed to change to scene %s" % current_scene_path)
		
		var _error = get_tree().change_scene("res://ui/TitleScreen.tscn")


func _reset_values_and_return_to_title_screen(save_data: SaveData) -> void:
	save_data.current_battle_index = 0
	save_data.current_battle_scene_index = 0
	
	var _error = get_tree().change_scene("res://ui/TitleScreen.tscn")
	
