extends Resource

class_name StatsModifier

export(Enums.StatsType) var modified_stat: int = Enums.StatsType.NONE

# How much the stat is modified
# For skill activation rate this value is added to the stat, not multiplied
export(float, -1, 1, 0.1) var modified_stat_percentage: float

# Modified status effect; which status effect this class
# grants resistance or vulnerability to
export(Enums.StatusEffectType) var modified_status_effect: int = Enums.StatusEffectType.NONE

# How much vulnerability or resistance this class grants
# < 0 -> grant resistance
# > 0 -> grant vulnerability
export(float, -1, 1, 0.1) var modified_status_effect_vulnerability: float

# Max duration in turns
export(int, 0, 5, 1) var duration_turns: int = 0

export(Texture) var icon = null


func modify_stats(base_stats: StartingStats, modified_stats: StartingStats) -> void:
	match(modified_stat):
		Enums.StatsType.ATTACK:
			modified_stats.attack += base_stats.attack * modified_stat_percentage
			
		Enums.StatsType.DEFENSE:
			modified_stats.defense += base_stats.defense * modified_stat_percentage
		
		Enums.StatsType.SPIRITUAL_ATTACK:
			modified_stats.spiritual_attack += base_stats.spiritual_attack * modified_stat_percentage
		
		Enums.StatsType.SPIRITUAL_DEFENSE:
			modified_stats.spiritual_defense += base_stats.spiritual_defense * modified_stat_percentage
		
		Enums.StatsType.SKILL_ACTIVATION_RATE_MODIFIER:
			modified_stats.skill_activation_rate_modifier += modified_stat_percentage
		
		Enums.StatsType.STATUS_EFFECT_VULNERABILITY:
			var status_effect_str: String = Enums.StatusEffectType.keys()[modified_status_effect]
			
			# Check modified status, in case a previous stats modifier added
			# a status effect vulnerability
			var vulnerability: float = modified_stats.status_ailment_vulnerabilities.get(status_effect_str, null)
			
			# If vulnerability is zero then unit is immune and the stat
			# is not modified
			# TODO: Stats modifier should not be inflicted if unit is immune to
			# modified status effect. Check this when applying it in Unit.gd
			if not is_zero_approx(vulnerability):
				if vulnerability == null:
					# Unit does not have vulnerability to modified status effect
					# Add the modifier to the general/base vulnerability
					var base_vulnerability: float = base_stats.status_ailment_vulnerability
					
					modified_stats.status_ailment_vulnerabilities[status_effect_str] = base_vulnerability + modified_status_effect_vulnerability
				else:
					modified_stats.status_ailment_vulnerabilities[status_effect_str] = vulnerability + modified_status_effect_vulnerability


func is_buff() -> bool:
	return modified_stat_percentage > 0 or modified_status_effect_vulnerability < 0


# TODO: Move to class shared with StatusEffect?
var _turn_count: int = duration_turns


func update() -> void:
	_turn_count -= 1


func is_done() -> bool:
	return _turn_count <= 0
