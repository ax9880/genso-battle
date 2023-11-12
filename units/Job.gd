extends Node

# Job
export(Resource) var job: Resource

export(int) var level: int = 0

var base_stats: StartingStats

# Stats after buffs and debuffs
var current_stats: StartingStats

# Array<Skill>
var skills: Array

signal health_changed(current_health, max_health)


func _ready() -> void:
	_update_stats()


func get_unlocked_skills() -> Array:
	# TODO: Convert job level to "max skills" count
	return skills.slice(0, level - 1)


func set_job_reference(job_reference: JobReference) -> void:
	job = job_reference.job
	level = job_reference.level
	
	_update_stats()


func _update_stats() -> void:
	base_stats = job.stats.duplicate()
	
	current_stats = base_stats.duplicate()
	
	skills = job.skills


func decrease_health(value: int) -> void:
	current_stats.health = int(clamp(current_stats.health - value, 0, base_stats.health))
	
	emit_signal("health_changed", current_stats.health, base_stats.health)
