extends Node

class Stats extends Reference:
	var health = 0

export (Resource) var starting_stats: Resource

var base_stats: StartingStats

# Stats after buffs and debuffs
var current_stats: StartingStats

var level: int = 0
var experience: int = 0

func _ready() -> void:
	var stats := starting_stats as StartingStats
	
	# TODO: Modify according to level
	base_stats = stats.duplicate()
	
	current_stats = base_stats.duplicate()
