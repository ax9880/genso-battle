class_name StatsModifier
extends StatusEffect


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


func modify_stats(base_stats: Stats, modified_stats: Stats) -> void:
	match(modified_stat):
		Enums.StatsType.ATTACK:
			modified_stats.attack += int(base_stats.attack * modified_stat_percentage)
			
		Enums.StatsType.DEFENSE:
			modified_stats.defense += int(base_stats.defense * modified_stat_percentage)
		
		Enums.StatsType.SPIRITUAL_ATTACK:
			modified_stats.spiritual_attack += int(base_stats.spiritual_attack * modified_stat_percentage)
		
		Enums.StatsType.SPIRITUAL_DEFENSE:
			modified_stats.spiritual_defense += int(base_stats.spiritual_defense * modified_stat_percentage)
		
		Enums.StatsType.SKILL_ACTIVATION_RATE_MODIFIER:
			modified_stats.skill_activation_rate_modifier += modified_stat_percentage
		
		Enums.StatsType.STATUS_EFFECT_VULNERABILITY:
			var vulnerability: float = modified_stats.get_vulnerability(modified_status_effect)
			
			# TODO: Stats modifier should not be inflicted if unit is immune to
			# modified status effect. Check this when applying it in Unit.gd
			
			# If vulnerability is zero then unit is immune and the stat
			# is not modified
			if not is_zero_approx(vulnerability):
				var status_effect_str: String = Enums.status_effect_type_to_string(modified_status_effect)
				
				modified_stats.status_ailment_vulnerabilities[status_effect_str] = vulnerability + modified_status_effect_vulnerability


func is_buff() -> bool:
	return .is_buff() and (modified_stat_percentage > 0 or modified_status_effect_vulnerability < 0)


func get_description(can_show_remaining_turns: bool = true) -> String:
	var status_effect_description: String = ""
	
	if modified_stat != Enums.StatsType.NONE:
		var modified_stat_key: String = Enums.StatsType.keys()[modified_stat]
		
		status_effect_description += "%s %+.0f%%" % [tr(modified_stat_key), (100.0 * modified_stat_percentage)]
		
		if modified_status_effect != Enums.StatusEffectType.NONE:
			status_effect_description += ", "
	
	if modified_status_effect != Enums.StatusEffectType.NONE:
		var modified_status_effect_key: String = Enums.status_effect_type_to_string(modified_status_effect)
		
		status_effect_description += tr("STATUS_EFFECT_RESISTANCE") % [(100.0 * modified_status_effect_vulnerability), modified_status_effect_key]
	
	if can_show_remaining_turns:
		status_effect_description += ", " + tr("TURNS_LEFT") % turn_count
	
	return status_effect_description
