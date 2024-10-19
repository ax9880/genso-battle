extends Node


class SkillEvaluationResult extends Reference:
	var cell: Cell = null
	var damage_dealt: int = 0
	var units_affected: int = 0
	var units_killed: int = 0
	var target_cells: Array = []


class DamageSorter:
	static func sort_descending(a: SkillEvaluationResult, b: SkillEvaluationResult) -> bool:
		if a.cell.unit == null and b.cell.unit != null:
			return true
		elif a.cell.unit != null and b.cell.unit == null:
			return false
		
		return a.damage_dealt > b.damage_dealt


class UnitsAffectedSorter:
	static func sort_descending(a: SkillEvaluationResult, b: SkillEvaluationResult) -> bool:
		if a.units_affected > b.units_affected:
			return true
		else:
			return a.damage_dealt > b.damage_dealt


class UnitsKilledSorter:
	static func sort_descending(a: SkillEvaluationResult, b: SkillEvaluationResult) -> bool:
		if a.units_killed > b.units_killed:
			return true
		else:
			return a.damage_dealt > b.damage_dealt


func evaluate_skill(unit: Unit,
					grid: Grid,
					allies: Array,
					enemies: Array,
					navigation_graph: Dictionary,
					skill: Skill,
					var preference: int) -> Array:
	var skill_evaluation_results: Array = []
	
	# For each cell you can travel to:
	for cell in navigation_graph:
		var skill_evaluation_result := SkillEvaluationResult.new()
		
		skill_evaluation_result.cell = cell
		
		var target_cells: Array = get_target_cells(unit, cell.position, skill, grid, allies, enemies)
		
		skill_evaluation_result.target_cells = target_cells
		
		for targeted_cell in target_cells:
			var targeted_unit: Unit = targeted_cell.unit
			
			if targeted_unit != null:
				var estimated_damage: int = 0
				
				# Check if units are enemies or allies in case cells are not filtered
				if targeted_unit.is_enemy(unit.faction) and skill.is_attack():
					estimated_damage = _estimate_damage(unit, targeted_unit, skill)
					
					skill_evaluation_result.units_affected += 1
					
					if (targeted_unit.get_stats().health - estimated_damage) <= 0:
						skill_evaluation_result.units_killed += 1
				elif targeted_unit.is_ally(unit.faction) and skill.is_healing():
					estimated_damage = _estimate_damage(unit, targeted_unit, skill)
					
					skill_evaluation_result.units_affected += 1
					
					# If skill heals, damage is negative
					estimated_damage = int(abs(estimated_damage))
				
				skill_evaluation_result.damage_dealt += estimated_damage
		
		skill_evaluation_results.push_back(skill_evaluation_result)
	
	_sort_by_preference(preference, skill_evaluation_results)
	
	return skill_evaluation_results


func _estimate_damage(unit: Unit, targeted_unit: Unit, skill: Skill) -> int:
	return targeted_unit.calculate_damage(unit.get_stats(), targeted_unit.get_stats(), skill.primary_power, skill.primary_weapon_type, skill.primary_attribute)


func _sort_by_preference(preference: int, skill_evaluation_results: Array) -> void:
	match(preference):
		Enums.Preference.DEAL_DAMAGE:
			skill_evaluation_results.sort_custom(DamageSorter, "sort_descending")
		Enums.Preference.AFFECT_UNITS:
			skill_evaluation_results.sort_custom(UnitsAffectedSorter, "sort_descending")
		Enums.Preference.RANDOM:
			skill_evaluation_results.shuffle()
		_:
			skill_evaluation_results.sort_custom(UnitsKilledSorter, "sort_descending")


func get_target_cells(unit: Unit,
					start_position: Vector2,
					skill: Skill,
					grid: Grid,
					allies: Array,
					enemies: Array) -> Array:
	# Don't filter cells, cells are only filtered when the skill will actually
	# be applied
	var can_filter_cells: bool = false
	
	return BoardUtils.find_area_of_effect_target_cells(unit, start_position, skill, grid, [], [], allies, enemies, can_filter_cells)
