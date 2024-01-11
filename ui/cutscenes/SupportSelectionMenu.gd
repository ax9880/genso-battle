extends Control


export(Resource) var chapter_data: Resource

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
	
	# If current chapter is already cleared then skip scene
	if save_data.is_chapter_cleared(chapter_data.title):
		print("Chapter %s already cleared. Skipping supports" % chapter_data.title)
		
		_return_to_pre_battle_menu()
	else:
		var max_support_level: int = _get_max_support_level(save_data)
		
		_set_up_button($MarginContainer/VBoxContainer2/VBoxContainer/YachieAndSakiButton, "YACHIE_AND_SAKI", save_data, max_support_level)
		_set_up_button($MarginContainer/VBoxContainer2/VBoxContainer/SakiAndYuumaButton, "SAKI_AND_YUUMA", save_data, max_support_level)
		_set_up_button($MarginContainer/VBoxContainer2/VBoxContainer/YuumaAndYachieButton, "YUUMA_AND_YACHIE", save_data, max_support_level)
		
		if _is_any_button_enabled():
			# TODO: If max_support_level is 4 then tell the player that they can only pick one
			# TODO: If a pair has support_level == 4 (max) then skip this scene
			pass
		else:
			# If all supports are locked, then show the return button
			$MarginContainer/VBoxContainer2/VBoxContainer/ReturnButton.show()
		
		# TODO: Tell the player that more support levels are unlocked as you progress in the story


func on_instance(data: Object) -> void:
	assert(data is ChapterData)
	
	chapter_data = data


func _set_up_button(button: Button, pair: String, save_data: SaveData, max_support_level: int) -> void:
	var next_support_level: int = save_data.supports.get(pair, 0) + 1
	
	button.disabled = not (next_support_level <= max_support_level)
	
	# TODO: Use formatted localized string
	button.text += " Lv. %d" % next_support_level
	
	if not button.disabled:
		var _error = button.connect("pressed", self, "_on_support_button_pressed", [pair, save_data, next_support_level])


func _return_to_pre_battle_menu() -> void:
	Loader.change_scene("res://ui/pre_battle_menu/StackBasedPreBattleMenu.tscn")


func _on_support_button_pressed(pair: String, save_data: SaveData, next_support_level: int) -> void:
	var support_dialogue_data := SupportDialogueData.new()
	
	support_dialogue_data.pair = pair
	support_dialogue_data.support_level = next_support_level
	
	_clear_chapter(chapter_data, pair)
	
	save_data.add_support_level(pair)
	
	# TODO: Update save file
	# Or do that just in pre-battle menu?
	
	Loader.change_scene("res://ui/cutscenes/SupportDialogueCutscene.tscn", support_dialogue_data)


func _on_ReturnButton_pressed() -> void:
	_clear_chapter(chapter_data)
	
	_return_to_pre_battle_menu()


func _is_any_button_enabled() -> bool:
	for button in $MarginContainer/VBoxContainer2/VBoxContainer.get_children():
		if button.visible and !button.disabled:
			return true
	
	return false


func _get_max_support_level(save_data: SaveData) -> int:
	var max_support_level: int = 0
	
	for support_level_chapter_data in support_level_chapters:
		if support_level_chapter_data != null and save_data.is_chapter_unlocked(support_level_chapter_data.title):
			max_support_level += 1
	
	return max_support_level


func _clear_chapter(current_chapter_data: ChapterData, _pair: String = "") -> void:
	# TODO: Design simpler way to unlock chapters
	var chapter_clearer: Node = null
	
	# TODO: On last chapter pre-betrayal, if you choose a level 4 support,
	# find ChapterClearer according to title + chosen pair
	for node in $ChapterClearers.get_children():
		if node.current_chapter_data.title == current_chapter_data.title:
			chapter_clearer = node
			
			break
	
	if chapter_clearer == null:
		printerr("Failed to find chapter clearer for chapter %s" % current_chapter_data.title)
	else:
		chapter_clearer.unlock_next_chapter()
