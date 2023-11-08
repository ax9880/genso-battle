extends "res://ui/cutscenes/DialogueCutscene.gd"


func _skip_dialogue() -> void:
	var save_data: SaveData = GameData.save_data
	
	save_data.current_battle_scene_index += 1
	
	._skip_dialogue()
