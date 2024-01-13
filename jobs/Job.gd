extends Resource

class_name Job

# StartingStats
# Has to be unique (duplicated)
export(Resource) var stats: Resource = null

# Array<Skill>
# Assuming one skill per level
export(Array, Resource) var skills: Array = []

export(String) var job_name: String = ""

export(Texture) var portrait: Texture = null

export(Texture) var full_portrait: Texture = null


func get_unlocked_skills(level: int) -> Array:
	if level <= 0:
		return []
	else:
		return skills.slice(0, level - 1)
