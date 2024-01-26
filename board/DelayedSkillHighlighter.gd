extends Node2D

class HighlightedSkill extends Reference:
	var unit: Unit
	var skill: Skill
	var skill_highlight: Node2D = null


export(PackedScene) var skill_highlight_packed_scene: PackedScene

# Only enemies use delayed skills so it's fine to just use one color
export(Color) var cell_highlight_color


# Array<HighlightedSkill>
var _highlighted_skills: Array = []


func highlight(unit: Unit, skill: Skill, target_cells: Array) -> void:
	var skill_highlight: Node2D = skill_highlight_packed_scene.instance()
	
	add_child(skill_highlight)
	skill_highlight.show_highlight(target_cells, cell_highlight_color)
	
	var highlighted_skill: HighlightedSkill = HighlightedSkill.new()
	highlighted_skill.unit = unit
	highlighted_skill.skill = skill
	highlighted_skill.skill_highlight = skill_highlight
	
	_highlighted_skills.push_back(highlighted_skill)


func remove(unit: Unit, skill: Skill) -> void:
	var highlighted_skill: HighlightedSkill = _find_highlighted_skill(unit, skill)
	
	if highlighted_skill != null:
		_remove_highlighted_skill(highlighted_skill)


func remove_all(unit: Unit) -> void:
	var highlights_to_remove: Array = []
	
	for highlighted_skill in _highlighted_skills:
		if highlighted_skill.unit == unit:
			highlights_to_remove.push_back(highlighted_skill)
	
	for highlighted_skill in highlights_to_remove:
		_remove_highlighted_skill(highlighted_skill)


func _remove_highlighted_skill(highlighted_skill: HighlightedSkill) -> void:
	highlighted_skill.skill_highlight.stop()
	
	_highlighted_skills.erase(highlighted_skill)


func _find_highlighted_skill(unit: Unit, skill: Skill) -> HighlightedSkill:
	for highlighted_skill in _highlighted_skills:
		if highlighted_skill.unit == unit and highlighted_skill.skill == skill:
			return highlighted_skill
	
	return null
