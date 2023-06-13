extends HBoxContainer


func initialize(skill: Skill) -> void:
	# The translation keys are the names of the enum values
	var area_of_effect_translation_key: String = Enums.AreaOfEffect.keys()[skill.area_of_effect]
	
	var skill_description: String = tr(skill.skill_name) + ", " + tr(area_of_effect_translation_key)
	
	if not skill.is_targeted_individually():
		skill_description += " (%d)" % skill.area_of_effect_size
	
	$Label.text = skill_description
	
	$TextureRect.texture = load(Enums.WEAPON_TYPE_TEXTURES[skill.primary_weapon_type])
