extends Resource

class_name JobReference


# Job
export(Resource) var job: Resource

# Unit level
export(int) var level: int


func to_dictionary() -> Dictionary:
	var dictionary := {}
	
	dictionary["job_resource_path"] = job.resource_path
	dictionary["level"] = level
	
	return dictionary


func from_dictionary(dictionary: Dictionary) -> void:
	job = load(dictionary.job_resource_path)
	
	level = dictionary.level


func get_job() -> Job:
	return job as Job
