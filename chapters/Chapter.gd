extends Node


export(PackedScene) var script_packed_scene: PackedScene

export(PackedScene) var dialogue_script_packed_scene: PackedScene

export(PackedScene) var post_battle_script_packed_scene: PackedScene

export(PackedScene) var supports_packed_scene: PackedScene


var title: String


func _ready() -> void:
	var save_data: SaveData = GameData.save_data
	
	var current_chapter: ChapterSaveData = save_data.unlocked_chapters.back()
	
	title = current_chapter.title
	
	var script = script_packed_scene.instance()
	
	script.scene_title = title
	
	script.connect("finished", self, "_on_Script_finished", [script])
	
	add_child(script)
	
	# fade in
	
	# enable after fade in


func _on_Script_finished(node: Node) -> void:
	# fade out if not faded out yet
	
	remove_child(node)
	
	var dialogue = dialogue_script_packed_scene.instance()
	
	dialogue.scene_title = title
	
	dialogue.connect("finished", self, "_on_Dialogue_finished")
	
	add_child(dialogue)
	
	# fade in
	
	# enable after fade in


func _on_Dialogue_finished(node: Node) -> void:
	var battle = script_packed_scene.instance()
	
	battle.connect("victory", self, "_on_Battle_victory", [battle])
	battle.connect("go_back", self, "_on_Battle_go_back")
	
	add_child(battle)


func _on_Battle_victory(node: Node) -> void:
	# fade out if not faded out yet
	
	remove_child(node)
	
	var post_battle_script = post_battle_script_packed_scene.instance()
	
	post_battle_script.scene_title = title
	
	post_battle_script.connect("finished", self, "_on_PostBattleScript_finished", [post_battle_script])
	
	add_child(post_battle_script)
	
	# fade in
	
	# enable after fade in


func _on_Battle_go_back() -> void:
	Loader.change_scene("TODO: Go back to pre-battle menu")


func _on_PostBattleScript_finished(node: Node) -> void:
	# fade out if not faded out yet
	
	remove_child(node)
	
	var supports_scene = supports_packed_scene.instance()
	
	supports_scene.scene_title = title
	
	supports_scene.connect("finished", self, "_on_SupportsPackedScene_finished")
	
	add_child(supports_scene)
	
	# fade in
	
	# enable after fade in
