extends Node

enum Preference {
	DEAL_DAMAGE,
	AFFECT_UNITS,
	KILL_UNITS_find_cells_close_to_enemies
}

class SkillEvaluationResult extends Reference:
	var cell: Cell = null
	var damage_dealt: int = 0
	var units_affected: int = 0
	var units_killed: int = 0
	var target_cells: Array = []


class PossiblePincer extends Reference:
	var cell: Cell = null
	var units_pincered_count: int = 0


class DamageSorter:
	static func sort_descending(a: SkillEvaluationResult, b: SkillEvaluationResult) -> bool:
		return a.damage_dealt > b.damage_dealt


class UnitsAffectedSorter:
	static func sort_descending(a: SkillEvaluationResult, b: SkillEvaluationResult) -> bool:
		return a.units_affected > b.units_affected


class UnitsKilledSorter:
	static func sort_descending(a: SkillEvaluationResult, b: SkillEvaluationResult) -> bool:
		return a.units_killed > b.units_killed


class UnitsPinceredSorter:
	static func sort_descending(a: PossiblePincer, b: PossiblePincer) -> bool:
		return a.units_pincered_count > b.units_pincered_count


func evaluate_skill(unit: Unit,
					grid: Grid,
					allies: Array,
					enemies: Array,
					navigation_graph: Dictionary,
					skill: Skill,
					var can_yield := false) -> Array:
	var skill_evaluation_results: Array = []
	
	# For each cell you can travel to:
	for cell in navigation_graph:
		var skill_evaluation_result := SkillEvaluationResult.new()
		
		skill_evaluation_result.cell = cell
		
		# Don't filter cells, cells are only filtered when the skill will actually
		# be applied
		var can_filter_cells: bool = false
		
		var target_cells: Array = BoardUtils.find_area_of_effect_target_cells(unit, cell.position, skill, grid, [], [], allies, enemies, can_filter_cells)
		skill_evaluation_result.target_cells = target_cells
		
		for targeted_cell in target_cells:
			var targeted_unit: Unit = targeted_cell.unit
			
			if targeted_unit != null:
				var estimated_damage: int = targeted_unit.calculate_damage(targeted_unit.get_stats(), unit.get_stats(), skill.primary_power, skill.primary_weapon_type, skill.primary_attribute)
				
				# Check if units are enemies or allies in case cells are not filtered
				if targeted_unit.is_enemy(unit.faction) and skill.is_attack():
					if unit.get_stats().health - estimated_damage <= 0:
						skill_evaluation_result.units_killed += 1
				elif targeted_unit.is_ally(unit.faction) and skill.is_healing():
					# If skill heals, damage is negative
					estimated_damage = int(abs(estimated_damage))
				
				skill_evaluation_result.units_affected += 1
				skill_evaluation_result.damage_dealt += estimated_damage
				
				if can_yield:
					yield(get_tree(), "idle_frame")
		
		skill_evaluation_results.push_back(skill_evaluation_result)
	
	_sort_by_preference(Preference.DEAL_DAMAGE, skill_evaluation_results)
	
	return skill_evaluation_results


func _sort_by_preference(preference: int, skill_evaluation_results: Array) -> void:
	match(preference):
		Preference.DEAL_DAMAGE:
			skill_evaluation_results.sort_custom(DamageSorter, "sort_descending")
		Preference.AFFECT_UNITS:
			skill_evaluation_results.sort_custom(UnitsAffectedSorter, "sort_descending")
		_:
			skill_evaluation_results.sort_custom(UnitsKilledSorter, "sort_descending")


# TODO: Find nav graph while marking ally cells as unpassable?
# Returns Array<PossiblePincer> with possible cells were the unit can navigate
# to to perform a pincer, ordered by how many units are affected.
func find_possible_pincers(unit: Unit, grid: Grid, allies: Array) -> Array:
	var possible_pincers: Array = []
	var directions := [Cell.DIRECTION.RIGHT, Cell.DIRECTION.LEFT, Cell.DIRECTION.UP, Cell.DIRECTION.DOWN]
	
	for ally in allies:
		if ally != unit and ally.can_act():
			var cell: Cell = grid.get_cell_from_position(ally.position)
			
			for direction in directions:
				var possible_pincer: PossiblePincer = _find_possible_pincer(cell, unit.faction, direction)
				
				if possible_pincer != null:
					possible_pincers.push_back(possible_pincer)
	
	possible_pincers.sort_custom(UnitsPinceredSorter, "sort_descending")
	
	return possible_pincers


# Returns null if a possible pincer is not found
func _find_possible_pincer(cell: Cell, faction: int, direction: int) -> PossiblePincer:
	# Flag enabled if a possible pincer is found
	var candidate_cell: Cell = null
	
	var last_unit: Unit = null
	var units_pincered_count: int = 0
	
	var neighbor: Cell = cell.get_neighbor(direction)
	
	while neighbor != null:
		var next_unit = neighbor.unit
		
		# There is an available cell
		if next_unit == null:
			# This unit can move to this cell and perform a pincer
			if last_unit != null and last_unit.is_enemy(faction):
				candidate_cell = neighbor
			
			break
		elif next_unit.is_enemy(faction):
			last_unit = next_unit
			units_pincered_count += 1
			
			neighbor = neighbor.get_neighbor(direction)
		else:
			# Is an ally, a pincer is not possible
			break
	
	if candidate_cell != null:
		var possible_pincer := PossiblePincer.new()
		
		possible_pincer.cell = candidate_cell
		possible_pincer.units_pincered_count = units_pincered_count
		
		return possible_pincer
	else:
		return null
