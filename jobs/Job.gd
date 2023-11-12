extends Resource

class_name Job

# StartingStats
# Has to be unique (duplicated)
export(Resource) var stats: Resource = null

# Array<Skill>
export(Array, Resource) var skills: Array = []

export(String) var job_name: String = ""

export(Texture) var portrait: Texture = null

export(Texture) var full_portrait: Texture = null
