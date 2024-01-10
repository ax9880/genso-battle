extends StackBasedMenuScreen


# Check if files TITLE_<PAIR>_SUPPORT exist
# When player presses button:
# Change to support scene? Set/pass chapter data and selected support
# 	Or just selected file TITLE_<PAIR>_SUPPORT
# Save which support you chose
# Mark the chapter as cleared, invoke the Chapter clearer and update the save file
# If you unlocked new units then notify that when you return to the pre-battle menu

export(Array, Resource) var support_level_chapters: Array


func _ready() -> void:
	var save_data: SaveData = GameData.save_data
	
	var max_support_level: int = _get_support_level(save_data)
	
	_set_up_button($MarginContainer/VBoxContainer2/VBoxContainer/YachieAndSakiButton, "YACHIE_AND_SAKI", save_data, max_support_level)
	_set_up_button($MarginContainer/VBoxContainer2/VBoxContainer/SakiAndYuumaButton, "SAKI_AND_YUUMA", save_data, max_support_level)
	_set_up_button($MarginContainer/VBoxContainer2/VBoxContainer/YuumaAndYachieButton, "YUUMA_AND_YACHIE", save_data, max_support_level)
	
	# TODO: If all supports are locked, then skip this scene
	# But clear the chapter and all that
	
	# TODO: If max_support_level is 4 then tell the player that they can only pick one
	# TODO: If a pair has support_level == 4 (max) then skip this scene
	
	# TODO: Tell the player that more support levels are unlocked as you progress in the story
	
	# TODO: Hide or remove return button

func _set_up_button(button: Button, pair: String, save_data: SaveData, max_support_level: int) -> void:
	var next_support_level: int = save_data.supports.get(pair, 0) + 1
	
	button.disabled = not (next_support_level <= max_support_level)
	
	# TODO: Use formatted localized string
	button.text += " Lv. %d" % next_support_level
	
	if not button.disabled:
		button.connect("pressed", self, "_on_support_button_pressed", [pair, save_data, next_support_level])


func _on_support_button_pressed(pair: String, save_data: SaveData, next_support_level: int) -> void:
	# TODO: Use object
	var args := {}
	
	args["pair"] = pair
	args["next_support_level"] = next_support_level
	
	Loader.change_scene("res://ui/cutscenes/SupportDialogueCutscene.tscn", args)


func _on_ReturnButton_pressed() -> void:
	change_scene("res://ui/pre_battle_menu/StackBasedPreBattleMenu.tscn")


func _get_support_level(save_data: SaveData) -> int:
	var support_level: int = 0
	
	for chapter_data in support_level_chapters:
		if chapter_data != null and save_data.find_unlocked_chapter_by_title(chapter_data.title) != null:
			support_level += 1
	
	return support_level
