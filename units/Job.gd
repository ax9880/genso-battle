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
	_set_stats()


func get_unlocked_skills() -> Array:
	return job.get_unlocked_skills(level)


func set_job_reference(job_reference: JobReference) -> void:
	job = job_reference.job
	level = job_reference.level
	
	_set_stats()


func reset_stats() -> void:
	var current_health: int = current_stats.health
	
	_set_stats()
	
	current_stats.health = int(min(base_stats.health, current_health))


func _set_stats() -> void:
	base_stats = job.stats.duplicate()
	
	current_stats = base_stats.duplicate()
	
	skills = job.skills


func decrease_health(value: int) -> void:
	current_stats.health = int(clamp(current_stats.health - value, 0, base_stats.health))
	
	emit_signal("health_changed", current_stats.health, base_stats.health)
