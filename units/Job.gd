extends Node

# TODO: Merge with unit script

# Job
export(Resource) var job: Resource

export(int) var level: int = 0

var base_stats: Stats

# Stats after buffs and debuffs
var current_stats: Stats

# Array<Skill>
var skills: Array

signal health_changed(current_health, max_health)


func get_unlocked_skills() -> Array:
	return job.get_unlocked_skills(level)


func set_job(_job: Job) -> void:
	job = _job
	level = job.level
	
	_reset_base_stats()
	_reset_current_stats()


func set_level(value: int) -> void:
	level = value
	
	_reset_base_stats()
	_reset_current_stats()


func reset_stats() -> void:
	var current_health: int = current_stats.health
	
	_reset_current_stats()
	
	current_stats.health = int(min(base_stats.health, current_health))


func decrease_health(value: int) -> void:
	current_stats.health = int(clamp(current_stats.health - value, 0, base_stats.health))
	
	emit_signal("health_changed", current_stats.health, base_stats.health)


func _reset_base_stats() -> void:
	base_stats = job.stats.duplicate()
	base_stats.level = level


func _reset_current_stats() -> void:
	current_stats = base_stats.duplicate()
	current_stats.level = level
	
	skills = job.skills
