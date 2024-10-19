tool
extends EditorPlugin
# This plugin loads the chapter list and inspects each battle scene to get the
# number of enemy types for each weapon type and the total number of enemy
# phases. It then updates the ChapterList resource with this information.
# When the pre-battle menu loads the chapter list, it can use the information
# in the resource to show that in the menu.


const CHAPTER_LIST_PATH := "res://chapter_data/MainStoryChapterList.tres"


func _enter_tree() -> void:
	pass


func build() -> bool:
	var chapter_list: ChapterList = load(CHAPTER_LIST_PATH)
	
	var results: Dictionary = {}
	
	for chapter in chapter_list.chapters:
		var battle_scene_path: String = chapter.battle_scene_path
		
		var battle_packed_scene: Resource = load(battle_scene_path)
		var battle = battle_packed_scene.instance()
		
		var enemy_phases: Node2D = battle.get_node("Board/EnemyPhases")
		
		chapter.battle_info = _process_phases(enemy_phases)
	
	ResourceSaver.save(CHAPTER_LIST_PATH, chapter_list)
	
	return true


func _exit_tree() -> void:
	pass


func _process_phases(enemy_phases: Node2D) -> BattleInfo:
	var battle_info = BattleInfo.new()
	
	for phase in enemy_phases.get_children():
		if phase.get_child_count() > 0:
			battle_info.phases_count += 1
			
			for enemy in phase.get_children():
				var job = enemy.get_node("Job")
				
				var weapon_type: int = job.job.stats.weapon_type
				
				match(weapon_type):
					Enums.WeaponType.SWORD:
						battle_info.sword_enemy_count += 1
					Enums.WeaponType.GUN:
						battle_info.gun_enemy_count += 1
					Enums.WeaponType.SPEAR:
						battle_info.spear_enemy_count += 1
					Enums.WeaponType.STAFF:
						battle_info.staff_enemy_count += 1
	
	return battle_info

