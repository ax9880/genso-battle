extends Node

# ChapterData
export(Resource) var current_chapter_data: Resource

# ChapterData
export(Resource) var next_chapter_data: Resource


export(Array, Resource) var unlocked_jobs: Array

export(int) var unlocked_jobs_level: int = 1

export(int) var levels_to_add: int = 0


func unlock_next_chapter() -> void:
	var save_data := GameData.save_data
	
	var current_chapter_save_data: ChapterSaveData = save_data.find_unlocked_chapter_by_title(current_chapter_data.title)
	
	if current_chapter_save_data == null:
		push_warning("Save data for current chapter %s is null. Unlocking this chapter" % current_chapter_data.title)
		
		save_data.unlock_chapter(current_chapter_data.title)
		
		current_chapter_save_data = save_data.find_unlocked_chapter_by_title(current_chapter_data.title)
	
	assert(current_chapter_save_data != null)
	
	if current_chapter_save_data.is_cleared:
		print("Already cleared %s" % current_chapter_data.title)
	else:
		# Mark as cleared
		current_chapter_save_data.is_cleared = true
		
		# Add next level to list of unlocked levels
		if next_chapter_data == null:
			push_warning("Chapter %s has no data for next chapter" % current_chapter_data.title)
		else:
			save_data.unlock_chapter(next_chapter_data.title)
		
		_increase_levels(save_data)
		_add_unlocked_jobs(save_data)


func _increase_levels(save_data: SaveData) -> void:
	for job in save_data.jobs:
		job.level += levels_to_add


func _add_unlocked_jobs(save_data: SaveData) -> void:
	# TODO: For level, use same level as first active unit ?
	for job in unlocked_jobs:
		save_data.add_job(job, unlocked_jobs_level)
