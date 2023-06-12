extends Resource

class_name Job

# StartingStats
# Has to be unique (duplicated)
export(Resource) var stats: Resource = null

# Array<Skill>
export(Array, Resource) var skills: Array = []

export(String) var job_name: String = ""

export(Texture) var portrait: Texture = null

export(String, FILE, "*.tscn") var unit_scene_path: String = ""

# Between 1 and 3. Level determines how many skills are unlocked.
export(int) var level: int = 1


func to_dictionary() -> Dictionary:
	var dictionary := {}
	
	dictionary["stats"] = stats.resource_path
	
	var skills_paths := []
	
	for skill in skills:
		skills_paths.append(skill.resource_path)
	
	dictionary["skills"] = skills_paths
	dictionary["job_name"] = job_name
	dictionary["portrait"] = portrait.resource_path
	dictionary["unit_scene_path"] = unit_scene_path
	dictionary["level"] = level
	
	return dictionary


func from_dictionary(dictionary: Dictionary) -> void:
	stats = StartingStats.new()
	
	stats = load(dictionary.stats)
	
	skills = []
	
	for skill in dictionary.skills:
		skills.push_back(load(skill))
		
	job_name = dictionary.job_name
	portrait = load(dictionary.portrait)
	unit_scene_path = unit_scene_path
	level = level
