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
	
	var current_chapter_save_data = save_data.find_unlocked_chapter_by_title(current_chapter_data.title)
	
	assert(current_chapter_save_data != null)
	
	if current_chapter_save_data.is_cleared:
		# If already cleared, don't do anything
		print("Already finished %s" % current_chapter_data.title)
	else:
		# Mark as cleared
		current_chapter_save_data.is_cleared = true
		
		# Add next level to list of unlocked levels
		save_data.unlock_chapter(next_chapter_data.title)
		
		_increase_levels(save_data)
		_add_unlocked_jobs(save_data)


func _increase_levels(save_data: SaveData) -> void:
	for job_reference in save_data.job_references:
		job_reference.level += levels_to_add


func _add_unlocked_jobs(save_data: SaveData) -> void:
	# TODO: For level, use same level as first active unit ?
	for job in unlocked_jobs:
		save_data.add_job(job, unlocked_jobs_level)
