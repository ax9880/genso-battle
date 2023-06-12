extends HBoxContainer


func initialize(skill: Skill) -> void:
	$Label.text = tr(skill.skill_name)
	
	# TODO: Add area of effect
	
	$TextureRect.texture = load(Enums.WEAPON_TYPE_TEXTURES[skill.primary_weapon_type])
