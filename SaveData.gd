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

# Dictionary<String (battle title), int (current index of scene of said battle)>
export(Dictionary) var battle_progress: Dictionary = {}

# TODO: Save in file
export(int) var current_battle_index: int = 0
export(int) var current_battle_scene_index: int = 0

# TODO: chosen supports

export(float) var music_volume: float = 1.0
export(float) var sound_effects_volume: float = 1.0

export(String, "en", "es") var locale: String = ""
export(Enums.DragMode) var drag_mode: int = Enums.DragMode.CLICK


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
