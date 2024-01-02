extends Resource

class_name SaveData


const MAX_SQUAD_SIZE: int = 6
const MIN_SQUAD_SIZE: int = 2

export(int) var version: int = 1

# Array<JobReference>
# Jobs that the player has 
export(Array, Resource) var job_references: Array = []

# Array<int>
export(Array, int) var active_units: Array = []

export(float) var music_volume: float = 1.0
export(float) var sound_effects_volume: float = 1.0

export(String, "en", "es") var locale: String = ""
export(Enums.DragMode) var drag_mode: int = Enums.DragMode.CLICK

# TODO: Supports

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
	var chapter_list: ChapterList = load("res://save_data/chapter_data/MainStoryChapterList.tres")
	
	return chapter_list.find_by_title(title)


func find_unlocked_chapter_by_title(title: String) -> ChapterSaveData:
	for chapter_save_data in unlocked_chapters:
		if chapter_save_data.title == title:
			return chapter_save_data
	
	return null


func add_job(job: Job, level: int) -> void:
	var job_reference: JobReference = JobReference.new()
	
	job_reference.job = job
	job_reference.level = level
	
	job_references.push_back(job_reference)


func swap_job_references(old_job_reference: JobReference, new_job_reference: JobReference) -> void:
	if old_job_reference != null:
		var index_of_old_job_reference: int = job_references.find(old_job_reference)
		
		assert(index_of_old_job_reference != -1)
		
		var index_of_old_job_reference_in_active_units: int = active_units.find(index_of_old_job_reference)
		
		assert(index_of_old_job_reference_in_active_units != -1)
		
		var index_of_new_job_reference: int = job_references.find(new_job_reference)
		
		assert(index_of_new_job_reference != -1)
		
		var index_of_new_job_reference_in_active_units: int = active_units.find(index_of_new_job_reference)
		
		active_units[index_of_old_job_reference_in_active_units] = index_of_new_job_reference
		
		if index_of_new_job_reference_in_active_units != -1:
			active_units[index_of_new_job_reference_in_active_units] = index_of_old_job_reference
	else:
		var index_of_new_job_reference: int = job_references.find(new_job_reference)
		
		assert(index_of_new_job_reference != -1)
		
		active_units.push_back(index_of_new_job_reference)
		
		assert(active_units.size() <= MAX_SQUAD_SIZE)


func remove_job_reference(job_reference: JobReference) -> void:
	if job_reference != null:
		var index: int = job_references.find(job_reference)
		
		assert(index != -1)
		
		active_units.erase(index)
