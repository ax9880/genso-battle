extends StatusEffect


func modify_stats(_base_stats: Stats, modified_stats: Stats) -> void:
	modified_stats.attack = 0
	
	modified_stats.skill_activation_rate_modifier = -1
