extends "res://ui/DialogueCutscene.gd"


func _skip_dialogue() -> void:
	var save_data: SaveData = GameData.save_data
	
	save_data.current_battle_scene_index += 1
	
	var _error = get_tree().change_scene("res://ui/PreBattleMenu.tscn")
