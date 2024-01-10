extends "res://ui/cutscenes/DialogueCutscene.gd"


export(String) var pair: String = "YACHIE_AND_SAKI"
export(int, 1, 4) var support_level: int = 1


func on_instance(data: Object) -> void:
	assert(data is SupportDialogueData)
	
	pair = data.pair
	support_level = data.support_level


func get_dialogue_json_filename() -> String:
	return "res://text/support_level_%d_%s.json" % [support_level, pair.to_lower()]


func _skip_dialogue() -> void:
	# TODO: Pass chapter data...?
	if Loader.change_scene("res://ui/pre_battle_menu/StackBasedPreBattleMenu.tscn") != OK:
		printerr("Failed to change scene")
	
	set_process(false)
