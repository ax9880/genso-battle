class_name SaveData
extends Resource


const MAX_SQUAD_SIZE: int = 6
const MIN_SQUAD_SIZE: int = 2

export(int) var version: int = 1

# Array<Job>
# Jobs that the player has
export(Array, Resource) var jobs: Array = []

# Array<int>
export(Array, int) var active_units: Array = []

export(float) var music_volume: float = 1.0
export(float) var sound_effects_volume: float = 1.0

export(String, "en", "es") var locale: String = ""
export(Enums.DragMode) var drag_mode: int = Enums.DragMode.CLICK

# Dictionary<String (Pair), int (support level, 1 - 4)>
# TODO: Save and load from file
var supports: Dictionary = {}

# Array<ChapterSaveData>
var unlocked_chapters: Array = []

var current_chapter: ChapterData


func unlock_chapter(title: String) -> void:
	var chapter: ChapterData = find_chapter_data_by_title(title)
	
	assert(chapter != null)
	
	var chapter_save_data = find_unlocked_chapter_by_title(title)
	
	if chapter_save_data != null:
		print("Chapter %s already unlocked" % title)
	else:
		var unlocked_chapter: ChapterSaveData = ChapterSaveData.new()
		
		unlocked_chapter.title = chapter.title
		
		unlocked_chapters.push_back(unlocked_chapter)


func find_chapter_data_by_title(title: String) -> ChapterData:
	var chapter_list: ChapterList = load("res://chapter_data/MainStoryChapterList.tres")
	
	return chapter_list.find_by_title(title)


func find_unlocked_chapter_by_title(title: String) -> ChapterSaveData:
	for chapter_save_data in unlocked_chapters:
		if chapter_save_data.title == title:
			return chapter_save_data
	
	return null


func is_chapter_unlocked(title: String) -> bool:
	return find_unlocked_chapter_by_title(title) != null


func is_chapter_cleared(title: String) -> bool:
	var chapter_save_data: ChapterSaveData = find_unlocked_chapter_by_title(title)
	
	return chapter_save_data != null && chapter_save_data.is_cleared


func add_job(job: Job, level: int) -> void:
	var new_job: Job = job.duplicate()
	new_job.stats = new_job.stats.duplicate()
	
	new_job.level = level
	
	jobs.push_back(new_job)


func swap_jobs(old_job: Job, new_job: Job) -> void:
	if old_job != null:
		var index_of_old_job: int = jobs.find(old_job)
		
		assert(index_of_old_job != -1)
		
		var index_of_old_job_in_active_units: int = active_units.find(index_of_old_job)
		
		assert(index_of_old_job_in_active_units != -1)
		
		var index_of_new_job: int = jobs.find(new_job)
		
		assert(index_of_new_job != -1)
		
		var index_of_new_job_in_active_units: int = active_units.find(index_of_new_job)
		
		active_units[index_of_old_job_in_active_units] = index_of_new_job
		
		if index_of_new_job_in_active_units != -1:
			active_units[index_of_new_job_in_active_units] = index_of_old_job
	else:
		var index_of_new_job: int = jobs.find(new_job)
		
		assert(index_of_new_job != -1)
		
		active_units.push_back(index_of_new_job)
		
		assert(active_units.size() <= MAX_SQUAD_SIZE)


func remove_job(job: Job) -> void:
	if job != null:
		var index: int = jobs.find(job)
		
		assert(index != -1)
		
		active_units.erase(index)


func add_support_level(pair: String) -> void:
	var current_support_level: int = supports.get(pair, 0)
	
	supports[pair] = current_support_level + 1
