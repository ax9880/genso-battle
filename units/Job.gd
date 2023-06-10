extends Node

class Stats extends Reference:
	var health = 0

export (Resource) var starting_stats: Resource

export (Array, Resource) var skills: Array

var base_stats: StartingStats

# Stats after buffs and debuffs
var current_stats: StartingStats

var level: int = 0
var experience: int = 0

# current_hp: int
signal health_changed(current_health, max_health)


func _ready() -> void:
	var stats := starting_stats as StartingStats
	
	# TODO: Modify according to level
	base_stats = stats.duplicate()
	
	current_stats = base_stats.duplicate()


func decrease_health(value: int) -> void:
	current_stats.health = int(clamp(current_stats.health - value, 0, base_stats.health))
	
	emit_signal("health_changed", current_stats.health, base_stats.health)
	
