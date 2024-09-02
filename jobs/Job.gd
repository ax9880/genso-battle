extends Resource

class_name Job

# Unlock skills every X levels
const _UNLOCK_SKILL_LEVEL_MULTIPLE: int = 10

# StartingStats
# Has to be unique (duplicated)
export(Resource) var stats: Resource = null

# Array<Skill>
export(Array, Resource) var skills: Array = []

export(String) var job_name: String = ""

export(Texture) var portrait: Texture = null

export(Texture) var full_portrait: Texture = null


func get_unlocked_skills(level: int) -> Array:
	var skills_unlocked_count: int = floor(level / _UNLOCK_SKILL_LEVEL_MULTIPLE)
	
	if skills_unlocked_count == 0:
		return []
	else:
		return skills.slice(0, skills_unlocked_count)
