extends HBoxContainer


func initialize(skill: Skill) -> void:
	$Label.text = skill.skill_name
