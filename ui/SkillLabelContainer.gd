extends HBoxContainer


func initialize(skill: Skill, can_show_full_data: bool = false) -> void:
	# The translation keys are the names of the enum values
	var area_of_effect_translation_key: String = Enums.AreaOfEffect.keys()[skill.area_of_effect]
	
	var skill_description: String = tr(skill.skill_name) + ", " + tr(area_of_effect_translation_key)
	
	if not skill.is_targeted_individually():
		skill_description += " (%d)" % skill.area_of_effect_size
	
	if can_show_full_data:
		$Label.autowrap = true
		
		skill_description += ", %.0f%%" % (100.0 * skill.activation_rate)
		
		var primary_weapon_type_translation_key: String = Enums.WeaponType.keys()[skill.primary_weapon_type]
		skill_description += ", %.1fx %s damage" % [skill.primary_power, primary_weapon_type_translation_key]
		
		if skill.secondary_power > 0:
			var secondary_weapon_type_translation_key: String = Enums.WeaponType.keys()[skill.secondary_weapon_type]
			
			skill_description += " (+%.1fx %s damage)" % [skill.secondary_power, secondary_weapon_type_translation_key]
		
		if skill.absorb_rate > 0:
			skill_description += ", absorb %.0f%%" % (skill.absorb_rate)
		
		if skill.status_effect != Enums.StatusEffectType.NONE:
			var status_effect_type_translation_key: String = Enums.StatusEffectType.keys()[skill.status_effect]
			
			skill_description += ", inflict %s for %d turns" % [status_effect_type_translation_key, skill.status_effect_duration_turns]
	
	$Label.text = skill_description
	
	$TextureRect.texture = load(Enums.WEAPON_TYPE_TEXTURES[skill.primary_weapon_type])
