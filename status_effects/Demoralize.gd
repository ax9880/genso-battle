extends StatusEffect


var random := RandomNumberGenerator.new()


func modify_stats(_base_stats: StartingStats, modified_stats: StartingStats) -> void:
	modified_stats.attack = 0
	
	modified_stats.skill_activation_rate_modifier = -1
