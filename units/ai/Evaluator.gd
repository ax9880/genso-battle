extends Node


enum ValidPath {
	NONE,
	PATH_A,
	PATH_B
}


class SkillEvaluationResult extends Reference:
	var cell: Cell = null
	var damage_dealt: int = 0
	var units_affected: int = 0
	var units_killed: int = 0
	var target_cells: Array = []


class DamageSorter:
	static func sort_descending(a: SkillEvaluationResult, b: SkillEvaluationResult) -> bool:
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


class UnitsPinceredSorter:
	static func sort_descending(a: PossiblePincer, b: PossiblePincer) -> bool:
		return a.units_pincered_count > b.units_pincered_count


# For two elements a and b, if the given method returns true, element b
# will be after element a in the array.
class PathLengthAndUnitsPinceredSorter:
	static func sort(a: PossiblePincer, b: PossiblePincer) -> bool:
		if b.end_cell.unit != null:
			return true
		
		if a.end_cell.unit != null:
			return false
		
		if a.units_pincered_count == b.units_pincered_count:
			var path_length_sum_a: int = a.start_cell_path_length + a.end_cell_path_length
			var path_length_sum_b: int = b.start_cell_path_length + b.end_cell_path_length
			
			return path_length_sum_a < path_length_sum_b
		else:
			return a.units_pincered_count > b.units_pincered_count


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
				var estimated_damage: int = targeted_unit.calculate_damage(unit.get_stats(), targeted_unit.get_stats(), skill.primary_power, skill.primary_weapon_type, skill.primary_attribute)
				
				# Check if units are enemies or allies in case cells are not filtered
				if targeted_unit.is_enemy(unit.faction) and skill.is_attack():
					skill_evaluation_result.units_affected += 1
					
					if (targeted_unit.get_stats().health - estimated_damage) <= 0:
						skill_evaluation_result.units_killed += 1
				elif targeted_unit.is_ally(unit.faction) and skill.is_healing():
					skill_evaluation_result.units_affected += 1
					
					# If skill heals, damage is negative
					estimated_damage = int(abs(estimated_damage))
				
				skill_evaluation_result.damage_dealt += estimated_damage
		
		skill_evaluation_results.push_back(skill_evaluation_result)
	
	_sort_by_preference(preference, skill_evaluation_results)
	
	return skill_evaluation_results


func _sort_by_preference(preference: int, skill_evaluation_results: Array) -> void:
	match(preference):
		Enums.Preference.DEAL_DAMAGE:
			skill_evaluation_results.sort_custom(DamageSorter, "sort_descending")
		Enums.Preference.AFFECT_UNITS:
			skill_evaluation_results.sort_custom(UnitsAffectedSorter, "sort_descending")
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


# Returns Array<PossiblePincer> with possible cells were the unit can navigate
# to to perform a pincer, and pincers it can coordinate with another ally
func find_possible_pincers(unit: Unit, grid: Grid, allies: Array, enemies: Array, navigation_graph: Dictionary, allies_queue: Array) -> Array:
	var start = OS.get_ticks_msec()
	
	var reachable_pincers: Array = _find_reachable_possible_pincers(unit, grid, navigation_graph, allies)
	
	var end = OS.get_ticks_msec()
	
	print("reachable_pincers %f" % [end - start])
	
	start = OS.get_ticks_msec()
	
	var coordinated_pincers: Array = _find_reachable_coordinated_pincers(unit, grid, enemies, navigation_graph, allies_queue)
	
	end = OS.get_ticks_msec()
	
	print("coordinated_pincers %f" % [end - start])
	
	reachable_pincers.append_array(coordinated_pincers)
	
	reachable_pincers.sort_custom(PathLengthAndUnitsPinceredSorter, "sort")
	
	return reachable_pincers


func _find_reachable_possible_pincers(unit: Unit, grid: Grid, navigation_graph: Dictionary, allies: Array) -> Array:
	var possible_pincers: Array = []
	
	for ally in allies:
		if ally != unit and ally.can_act():
			var cell: Cell = grid.get_cell_from_position(ally.position)
			
			if ally.is2x2():
				for area_cell in cell.get_cells_in_area():
					possible_pincers.append_array(_find_possible_pincers(area_cell, unit.faction))
			else:
				possible_pincers.append_array(_find_possible_pincers(cell, unit.faction))
	
	# Array<Cell>
	var corners: Array = grid.get_corners()
	
	for corner_cell in corners:
		var possible_pincer: PossiblePincer = _find_possible_corner_pincer(corner_cell, unit.faction)
		
		if possible_pincer != null:
			possible_pincers.push_back(possible_pincer)
	
	return _filter_reachable_possible_pincers(unit, grid, navigation_graph, possible_pincers)


func _filter_reachable_possible_pincers(unit: Unit, grid: Grid, navigation_graph: Dictionary, possible_pincers: Array) -> Array:
	var reachable_pincers: Array = []
	
	for possible_pincer in possible_pincers:
		var excluded_cells := {}
		
		excluded_cells[possible_pincer.start_cell] = true
		
		if unit.is2x2():
			for cell in possible_pincer.pincered_cells:
				excluded_cells[cell] = true
		
		var unit_path_to_end_cell: Array = BoardUtils.find_path(grid, navigation_graph, unit.position, possible_pincer.end_cell, excluded_cells)
		
		if not unit_path_to_end_cell.empty():
			possible_pincer.start_cell_path_length = 0
			possible_pincer.end_cell_path_length = unit_path_to_end_cell.size()
			
			possible_pincer.path_to_end_cell = unit_path_to_end_cell
			
			reachable_pincers.push_back(possible_pincer)
	
	return reachable_pincers


# Finds all possible pincers starting from start_cell and checking all
# four valid directions (right, left, up and down).
func _find_possible_pincers(start_cell: Cell, faction: int) -> Array:
	var possible_pincers: Array = []
	
	var directions := [Cell.DIRECTION.RIGHT, Cell.DIRECTION.LEFT, Cell.DIRECTION.UP, Cell.DIRECTION.DOWN]
	
	for direction in directions:
		var possible_pincer: PossiblePincer = _find_possible_pincer(start_cell, faction, direction)
		
		if possible_pincer != null:
			possible_pincers.push_back(possible_pincer)
	
	return possible_pincers


# Finds a possible pincer from the start cell in the given direction.
# If the unit in the start cell is not null, it must be an ally. A pincer
# is possible if there is one or more enemies in a row in the given direction
# and a free cell in the end.
# Returns null if a possible pincer is not found.
func _find_possible_pincer(start_cell: Cell, faction: int, direction: int) -> PossiblePincer:
	# Is not null if a possible pincer is found
	var candidate_cell: Cell = null
	
	var last_unit: Unit = null
	var units_pincered_count: int = 0
	
	var neighbor: Cell = start_cell.get_neighbor(direction)
	
	var pincered_cells: Array = []
	
	if start_cell.unit != null:
		assert(start_cell.unit.is_ally(faction))
	
	while neighbor != null:
		var next_unit = neighbor.unit
		
		# There is an available cell or there is an ally you can swap with
		if next_unit == null or (next_unit.is_ally(faction) and not next_unit.is2x2()):
			if last_unit != null and last_unit.is_enemy(faction):
				candidate_cell = neighbor
			
			break
		elif next_unit.is_enemy(faction):
			last_unit = next_unit
			units_pincered_count += 1
			
			pincered_cells.push_back(neighbor)
			
			neighbor = neighbor.get_neighbor(direction)
		else:
			break
	
	if candidate_cell != null:
		var possible_pincer := PossiblePincer.new()
		
		possible_pincer.start_cell = start_cell
		possible_pincer.end_cell = candidate_cell
		possible_pincer.units_pincered_count = units_pincered_count
		
		possible_pincer.pincered_cells = pincered_cells
		
		return possible_pincer
	else:
		return null


func _find_possible_corner_pincer(corner_cell: Cell, faction: int, is_coordinated: bool = false) -> PossiblePincer:
	# No unit in corner, or it's an ally. There's nothing to pincer
	if corner_cell.unit == null or corner_cell.unit.is_ally(faction):
		return null
	
	var neighbors: Array = corner_cell.neighbors
	
	assert(neighbors.size() == 2)
	
	var neighbor_1: Cell = neighbors[0]
	var neighbor_2: Cell = neighbors[1]
	
	var possible_pincer := PossiblePincer.new()
	
	possible_pincer.start_cell = neighbor_1
	possible_pincer.end_cell = neighbor_2
	
	possible_pincer.units_pincered_count = 1
	possible_pincer.pincered_cells.push_back(corner_cell)
	
	if is_coordinated and neighbor_1.unit == null and neighbor_2.unit == null:
		return possible_pincer
	elif _is_corner_pincer_possible(neighbor_1, neighbor_2, faction):
		return possible_pincer
	elif _is_corner_pincer_possible(neighbor_2, neighbor_1, faction):
		# Swap cells
		possible_pincer.start_cell = neighbor_2
		possible_pincer.end_cell = neighbor_1
		
		return possible_pincer
	else:
		return null


func _is_corner_pincer_possible(start_cell: Cell, end_cell: Cell, faction: int) -> bool:
	return start_cell.unit != null and start_cell.unit.is_ally(faction) and (end_cell.unit == null or end_cell.unit.is_ally(faction))


func _find_reachable_coordinated_pincers(unit: Unit, grid: Grid, enemies: Array, navigation_graph: Dictionary, allies_queue: Array) -> Array:
	var coordinated_pincers: Array = []
	
	var possible_pincers: Array = _find_coordinated_pincers(unit, grid, enemies)
	
	for ally in allies_queue:
		if ally.can_coordinate_pincer() and ally.is_alive():
			var ally_navigation_graph: Dictionary = BoardUtils.build_navigation_graph(grid, ally.position, ally.faction, ally.get_stats().movement_range)
			
			var reachable_pincers: Array = _find_reachable_pincers(unit, grid, navigation_graph, ally, ally_navigation_graph, possible_pincers)
			
			coordinated_pincers.append_array(reachable_pincers)
			
			# Stop with the first reachable pincer
			# TODO: Use other criteria? Limit how many allies the unit can look ahead?
			if not coordinated_pincers.empty():
				break
	
	return coordinated_pincers


# Array<PossiblePincer>
func _find_coordinated_pincers(unit: Unit, grid: Grid, enemies: Array) -> Array:
	var possible_pincers: Array = []
	
	for enemy in enemies:
		var cell: Cell = grid.get_cell_from_position(enemy.position)
		
		# Get neighbors of enemy. If there is a free cell then check if you
		# can perform a pincer from there
		for neighbor in cell.neighbors:
			if neighbor.unit == null:
				# Only search in two directions? Right and up?
				possible_pincers.append_array(_find_possible_pincers(neighbor, unit.faction))
	
	# Include pincers that include this unit
	# This is used to coordinate a pincer where this unit doesn't move, but
	# another unit does move.
	var cell: Cell = grid.get_cell_from_position(unit.position)
	
	if unit.is2x2():
		for area_cell in cell.get_cells_in_area():
			possible_pincers.append_array(_find_possible_pincers(area_cell, unit.faction))
	else:
		possible_pincers.append_array(_find_possible_pincers(cell, unit.faction))
	
	# Corner pincers
	var corners: Array = grid.get_corners()
	
	for corner_cell in corners:
		var is_coordinated: bool = true
		
		var possible_pincer: PossiblePincer = _find_possible_corner_pincer(corner_cell, unit.faction, is_coordinated)
		
		if possible_pincer != null:
			possible_pincers.push_back(possible_pincer)
	
	var pincers_without_duplicates: Array = []
	
	for pincer in possible_pincers:
		if not _has_pincer(pincers_without_duplicates, pincer):
			pincers_without_duplicates.append(pincer)

	return pincers_without_duplicates


func _has_pincer(possible_pincers: Array, possible_pincer: PossiblePincer) -> bool:
	for pincer in possible_pincers:
		if pincer.equals(possible_pincer):
			return true
	
	return false


func _find_reachable_pincers(unit: Unit, grid: Grid, navigation_graph: Dictionary, ally: Unit, ally_navigation_graph: Dictionary, possible_pincers: Array) -> Array:
	var coordinated_pincers: Array = []
	
	for possible_pincer in possible_pincers:
		if _is_pincer_reachable(unit, grid, navigation_graph, ally, ally_navigation_graph, possible_pincer):
			coordinated_pincers.push_back(possible_pincer)
	
	return coordinated_pincers


# Checks if pincer is reachable and modifies possible_pincer
func _is_pincer_reachable(unit: Unit, grid: Grid, navigation_graph: Dictionary, ally: Unit, ally_navigation_graph: Dictionary, possible_pincer: PossiblePincer) -> bool:
	var unit_excluded_start_cells := {}
	var unit_excluded_end_cells := {}
	
	var unit_cell: Cell = grid.get_cell_from_position(unit.position)
	var ally_cell: Cell = grid.get_cell_from_position(ally.position)
	
	_add_excluded_cells(unit, ally, ally_cell, possible_pincer, unit_excluded_start_cells, unit_excluded_end_cells)
	
	# Find paths
	var unit_path_to_end_cell: Array = BoardUtils.find_path(grid, navigation_graph, unit.position, possible_pincer.end_cell, unit_excluded_start_cells)
	var unit_path_to_start_cell: Array = BoardUtils.find_path(grid, navigation_graph, unit.position, possible_pincer.start_cell, unit_excluded_end_cells)
	
	if unit_path_to_end_cell.empty() and unit_path_to_start_cell.empty():
		return false
	
	possible_pincer.ally = ally
	possible_pincer.is_coordinated = true
	
	var excluded_start_cells := {}
	var excluded_end_cells := {}
	
	_add_excluded_cells(ally, unit, unit_cell, possible_pincer, excluded_start_cells, excluded_end_cells)
	
	var ally_path_to_start_cell: Array = BoardUtils.find_path(grid, ally_navigation_graph, ally.position, possible_pincer.start_cell, excluded_end_cells)
	var ally_path_to_end_cell: Array = BoardUtils.find_path(grid, ally_navigation_graph, ally.position, possible_pincer.end_cell, excluded_start_cells)
	
	# Compare the paths and select the best combination (reachable and shortest)
	var valid_path: int = _find_shortest_valid_path(ally_path_to_start_cell.size(), unit_path_to_end_cell.size(), unit_path_to_start_cell.size(), ally_path_to_end_cell.size(), possible_pincer, unit_cell)
	
	# The unit that is coordinating the pincer always moves to the end cell
	match(valid_path):
		ValidPath.PATH_A:
			possible_pincer.start_cell_path_length = ally_path_to_start_cell.size()
			possible_pincer.end_cell_path_length = unit_path_to_end_cell.size()
			
			possible_pincer.path_to_end_cell = unit_path_to_end_cell
			
			return true
		ValidPath.PATH_B:
			var end_cell: Cell = possible_pincer.end_cell
			
			# Swaps cells, this unit always moves to end_cell
			possible_pincer.end_cell = possible_pincer.start_cell
			possible_pincer.start_cell = end_cell
			
			# Swapped because start and end cells were swapped above
			possible_pincer.start_cell_path_length = ally_path_to_end_cell.size()
			possible_pincer.end_cell_path_length = unit_path_to_start_cell.size()
			
			possible_pincer.path_to_end_cell = unit_path_to_start_cell
			
			return true
		_:
			return false


# Modifies excluded_start_cells and excluded_end_cells
func _add_excluded_cells(unit: Unit, ally: Unit, ally_cell: Cell, possible_pincer: PossiblePincer, excluded_start_cells: Dictionary, excluded_end_cells: Dictionary) -> void:
	# Used to exclude the end cell from the path to the start cell, and viceversa
	excluded_start_cells[possible_pincer.start_cell] = true
	excluded_end_cells[possible_pincer.end_cell] = true
	
	# If unit is 2x2 exclude pincered cells and ally cell so that
	# the enemy doesn't push units around and ruin the set up
	if unit.is2x2():
		for cell in possible_pincer.pincered_cells:
			excluded_start_cells[cell] = true
			
			excluded_end_cells[cell] = true
		
		excluded_start_cells[ally_cell] = true
		excluded_end_cells[ally_cell] = true


# Returns ValidPath
func _find_shortest_valid_path(ally_path_to_start_cell_size: int, unit_path_to_end_cell_size: int, \
								unit_path_to_start_cell_size: int, ally_path_to_end_cell_size: int, \
								possible_pincer: PossiblePincer, unit_cell: Cell) -> int:
	if (ally_path_to_start_cell_size == 0 or unit_path_to_end_cell_size == 0) and (unit_path_to_start_cell_size == 0 or ally_path_to_end_cell_size == 0):
		return ValidPath.NONE
		
	if (ally_path_to_start_cell_size > 0 and unit_path_to_end_cell_size > 0) and (unit_path_to_start_cell_size == 0 or ally_path_to_end_cell_size == 0):
		return ValidPath.PATH_A
	
	if (ally_path_to_start_cell_size == 0 or unit_path_to_end_cell_size == 0) and (unit_path_to_start_cell_size > 0 and ally_path_to_end_cell_size > 0):
		# Path B is valid, swap cells
		return ValidPath.PATH_B
	
	var path_a_total_size: int = ally_path_to_start_cell_size + unit_path_to_end_cell_size
	var path_b_total_size: int = unit_path_to_start_cell_size + ally_path_to_end_cell_size
	
	if path_a_total_size < path_b_total_size:
		return ValidPath.PATH_A
	elif path_a_total_size == path_b_total_size:
		# If both paths are the same size, pick the cell based on the distance
		# of the unit to the end cell
		var unit_distance_to_start_cell: float = unit_cell.position.distance_squared_to(possible_pincer.start_cell.position)
		var unit_distance_to_end_cell: float = unit_cell.position.distance_squared_to(possible_pincer.end_cell.position)
		
		if unit_distance_to_end_cell < unit_distance_to_start_cell:
			return ValidPath.PATH_A
		else:
			return ValidPath.PATH_B
	else:
		# Path B is valid, swap cells
		return ValidPath.PATH_B
