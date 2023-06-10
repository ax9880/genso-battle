extends HBoxContainer


func initialize(skill: Skill) -> void:
	$Label.text = tr(skill.skill_name)
