extends HBoxContainer

const COMMA_AND_SPACE: String = ", "


func initialize(skill: Skill, can_show_full_data: bool = false) -> void:
	# The translation keys are the names of the enum values
	var area_of_effect_translation_key: String = Enums.AreaOfEffect.keys()[skill.area_of_effect]
	
	var skill_description: String = tr(skill.skill_name)
	
	if can_show_full_data:
		skill_description += ": " + tr(area_of_effect_translation_key)
	else:
		skill_description += ", " + tr(area_of_effect_translation_key).to_lower()
	
	if not skill.is_targeted_individually():
		skill_description += " (%d)" % skill.area_of_effect_size
	
	if can_show_full_data:
		$Label.autowrap = true
		
		skill_description += COMMA_AND_SPACE + "%.0f%%" % (100.0 * skill.activation_rate)
		
		if skill.is_attack():
			var primary_weapon_type_translation_key: String = Enums.WeaponType.keys()[skill.primary_weapon_type]
			
			skill_description += COMMA_AND_SPACE + tr("PRIMARY_WEAPON_DAMAGE_DESCRIPTION") % [skill.primary_power, tr(primary_weapon_type_translation_key).to_lower()]
		elif skill.is_healing():
			skill_description += COMMA_AND_SPACE + tr("HEAL_DESCRIPTION") % skill.primary_power
			
			skill_description += " " + tr("MAX_HEAL_DESCRIPTION").to_lower() % skill.max_heal
		
		if skill.secondary_power > 0:
			var secondary_weapon_type_translation_key: String = Enums.WeaponType.keys()[skill.secondary_weapon_type]
			
			skill_description += " " + tr("SECONDARY_WEAPON_DAMAGE_DESCRIPTION") % [skill.secondary_power, tr(secondary_weapon_type_translation_key).to_lower()]
		
		if skill.absorb_rate > 0:
			skill_description += COMMA_AND_SPACE + tr("ABSORB_DESCRIPTION") % (skill.absorb_rate * 100.0)
			
			skill_description += " " + tr("MAX_HEAL_DESCRIPTION").to_lower() % skill.max_heal
		
		if skill.status_effect != Enums.StatusEffectType.NONE:
			var status_effect_type_translation_key: String = Enums.StatusEffectType.keys()[skill.status_effect]
			
			skill_description += COMMA_AND_SPACE + tr("STATUS_EFFECT_DESCRIPTION") % [tr(status_effect_type_translation_key).to_lower(), skill.status_effect_duration_turns]
	
	$Label.text = skill_description
	
	$TextureRect.texture = load(Enums.WEAPON_TYPE_TEXTURES[skill.primary_weapon_type])
