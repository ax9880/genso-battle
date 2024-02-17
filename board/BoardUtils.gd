extends Node

class_name BoardUtils


# Builds an adjacency dictionary with all the nodes that the given unit can visit
# Enemies may block the unit from reaching certain tiles, besides the tiles they
# already occupy
static func build_navigation_graph(grid: Grid, unit_position: Vector2, faction: int, movement_range: int) -> Dictionary:
	var start_cell: Cell = grid.get_cell_from_position(unit_position)
	
	var queue := []
	
	queue.push_back(start_cell)
	
	# Dictionary<Cell, int (distance to start cell)>
	var discovered_dict := {}
	
	# Dictionary<Cell, Array<Cell> (array of cells connected to this cell)>
	# Graph as adjacency list
	var navigation_graph := {}
	
	var unit: Unit = start_cell.unit
	
	discovered_dict[start_cell] = 0
	
	while not queue.empty():
		var node: Cell = queue.pop_front()
		
		# Initialize adjacency list for the given node
		navigation_graph[node] = []
		
		for neighbor in node.neighbors:
			# Distance to this node is distance to the parent node + 1
			var distance: int = discovered_dict[node] + 1
			var cell_unit: Unit = neighbor.unit
			
			if not discovered_dict.has(neighbor):
				# Flag as discovered and set the distance
				discovered_dict[neighbor] = distance
				
				if _can_reach_cell(neighbor, distance, movement_range, unit, faction):
					navigation_graph[node].push_back(neighbor)
					
					queue.push_back(neighbor)
			else:
				# Add it to the adjacency list, but don't add it to the queue
				# This so that cells have all their neighbors in their
				# adjacency lists, and if one cell is excluded (when finding a
				# path) then a path can still be found through other cells. This
				# most notably affects 2x2 units.
				if _can_reach_cell(neighbor, distance, movement_range, unit, faction):
					navigation_graph[node].push_back(neighbor)
	
	return navigation_graph


static func _can_reach_cell(cell: Cell, distance: int, movement_range: int, unit: Unit, faction: int) -> bool:
	var cell_unit: Unit = cell.unit
	
	return (distance <= movement_range) and _can_enter_cell(unit, cell_unit, faction) and _can_fit_unit(unit, cell)


# 2x2 units can enter any cell, because they can push the unit inside said cell
# Single units ignore cells with 2x2 units, because they cannot swap with them
static func _can_enter_cell(unit: Unit, cell_unit: Unit, faction: int) -> bool:
	return cell_unit == null or \
			unit.is2x2() or \
			cell_unit.is_ally(faction) and not cell_unit.is2x2()


static func _can_fit_unit(unit: Unit, cell: Cell) -> bool:
	return not (unit.is2x2() and cell.get_cells_in_area().empty())


static func get_distance_to_cell(start_cell: Cell, end_cell: Cell) -> float:
	return abs(end_cell.coordinates.x - start_cell.coordinates.x) + abs(end_cell.coordinates.y - start_cell.coordinates.y)


static func find_path(grid: Grid, navigation_graph: Dictionary, unit_position: Vector2, target_cell: Cell, excluded_cells: Dictionary = {}) -> Array:
	var start_cell: Cell = grid.get_cell_from_position(unit_position)
	
	# Dictionary<Cell, bool>
	var discovered_dict := {}
	
	# Dictionary<Cell, Cell>
	var parent_dict := {}
	
	var queue := []
	queue.push_back(start_cell)
	
	parent_dict[start_cell] = null
	
	# TODO: Pass unit so that you can find paths for swap and pincer action
	var unit: Unit = start_cell.unit
	
	# Breadth-first search (again)
	while not queue.empty():
		var node: Cell = queue.pop_front()
		
		# Flag as discovered
		discovered_dict[node] = true
		
		if node == target_cell:
			break
		
		if (unit.is2x2() and node.get_cells_in_area().has(target_cell)) and (_is_cell_excluded(target_cell, unit, excluded_cells) or not navigation_graph.has(target_cell)):
			# If unit enters a cell that contains the target cell, and the
			# target cell is excluded, then moving to that other cell is enough
			target_cell = node
			
			break
		
		for neighbor in navigation_graph[node]:
			if not discovered_dict.has(neighbor) and not _is_cell_excluded(neighbor, unit, excluded_cells):
				queue.push_back(neighbor)
				
				parent_dict[neighbor] = node
	
	# Array of Cell
	var path := []
	
	# Rebuild the path
	if parent_dict.has(target_cell):
		var node_parent = parent_dict[target_cell]
		
		path.push_front(target_cell.position)
		
		while node_parent != null:
			path.push_front(node_parent.position)
			node_parent = parent_dict[node_parent]
	
	return path


static func _is_cell_excluded(cell: Cell, unit: Unit, excluded_cells: Dictionary) -> bool:
	if unit == null or not unit.is2x2():
		return excluded_cells.has(cell)
	else:
		for area_cell in cell.get_cells_in_area():
			if excluded_cells.has(area_cell):
				return true
		
		return false


# Returns Array<Cell>
# By default cells are filtered (meaning without cells with null units or with
# targeted units that are either allies or enemies depending on the skill type)
static func find_area_of_effect_target_cells(var unit: Unit,
		var start_position: Vector2,
		var skill: Skill,
		var grid: Grid,
		var pincered_units: Array = [], # Array<Unit>
		var chain: Array = [], # Array<Unit>, including the pincering unit that started the chain
		var allies: Array = [], # Array<Unit>
		var enemies: Array = [], # Array<Unit>
		var can_filter_cells: bool = true
	) -> Array:
	
	var cell: Cell = grid.get_cell_from_position(start_position)
	
	var target_cells := []
	
	# For 2x2 units and skills that target areas, the final area is the union of all
	# the targeted cells starting from each cell occupied by the 2x2 unit. If the
	# 2x2 unit appears in more than one cell in the list, it is okay because
	# the skill effect node keeps track of affected units and will not apply a 
	# skill to the same unit twice
	if unit.is2x2() and not skill.is_targeted_individually():
		var cells: Array = cell.get_cells_in_area()
		
		for area_cell in cells:
			target_cells.append_array(_find_area_of_effect(area_cell, skill, grid, pincered_units, chain, allies, enemies))
	else:
		target_cells = _find_area_of_effect(cell, skill, grid, pincered_units, chain, allies, enemies)
	
	if can_filter_cells:
		return filter_cells(unit, skill, target_cells)
	else:
		return _remove_duplicates(target_cells)


static func _find_area_of_effect(var cell: Cell, # Start cell from which skill is called
		var skill: Skill,
		var grid: Grid,
		var pincered_units: Array, # Array<Unit>
		var chain: Array, # Array<Unit>, including the pincering unit that started the chain
		var allies: Array, # Array<Unit>
		var enemies: Array # Array<Unit>
	) -> Array:
	match(skill.area_of_effect):
		Enums.AreaOfEffect.NONE, Enums.AreaOfEffect.PINCER:
			return _units_to_cells(grid, pincered_units)
		Enums.AreaOfEffect.AREA_X:
			var targets := []
			
			for x in range(cell.coordinates.x - skill.area_of_effect_size, cell.coordinates.x + skill.area_of_effect_size + 1):
				for y in range(cell.coordinates.y - skill.area_of_effect_size, cell.coordinates.y + skill.area_of_effect_size + 1):
					var candidate_cell_coordinates := Vector2(x, y)
					
					if grid._is_in_range(candidate_cell_coordinates):
						targets.push_back(grid.get_cell_from_coordinates(candidate_cell_coordinates))
			
			return targets
		Enums.AreaOfEffect.CROSS_X:
			var targets := []
			
			targets.append_array(_find_horizontal_x_cells(grid, cell, skill.area_of_effect_size))
			targets.append_array(_find_vertical_x_cells(grid, cell, skill.area_of_effect_size))
			
			return targets
		Enums.AreaOfEffect.SELF:
			return [cell]
		Enums.AreaOfEffect.HORIZONTAL_X:
			return _find_horizontal_x_cells(grid, cell, skill.area_of_effect_size)
		Enums.AreaOfEffect.VERTICAL_X:

			return _find_vertical_x_cells(grid, cell, skill.area_of_effect_size)
		Enums.AreaOfEffect.ROWS_X:
			var targets := []
			
			var start: int
			var area_of_effect_size_halved := int(float(skill.area_of_effect_size) / 2.0)
			
			if skill.area_of_effect_size % 2 == 0:
				start = int(cell.coordinates.y) - area_of_effect_size_halved + 1
			else:
				start = int(cell.coordinates.y) - area_of_effect_size_halved
			
			var end: int = int(cell.coordinates.y) + area_of_effect_size_halved
			
			assert(start <= end)
			
			for x in range(grid.width):
				for y in range(start, end + 1):
					var candidate_cell_coordinates := Vector2(x, y)
					
					if grid._is_in_range(candidate_cell_coordinates):
						targets.push_back(grid.get_cell_from_coordinates(candidate_cell_coordinates))
			
			return targets
		Enums.AreaOfEffect.COLUMNS_X:
			var targets := []
			
			var start: int
			var area_of_effect_size_halved := int(float(skill.area_of_effect_size) / 2.0)
			
			if skill.area_of_effect_size % 2 == 0:
				start = int(cell.coordinates.x) - area_of_effect_size_halved + 1
			else:
				start = int(cell.coordinates.x) - area_of_effect_size_halved
			
			var end: int = int(cell.coordinates.x) + area_of_effect_size_halved
			
			assert(start <= end)
			
			for x in range(start, end + 1):
				for y in range(grid.height):
					var candidate_cell_coordinates := Vector2(x, y)
					
					if grid._is_in_range(candidate_cell_coordinates):
						targets.push_back(grid.get_cell_from_coordinates(candidate_cell_coordinates))
			
			return targets
		Enums.AreaOfEffect.CHAIN:
			return _units_to_cells(grid, chain)
		Enums.AreaOfEffect.ALL:
			var all_units := []
			
			all_units.append_array(allies)
			all_units.append_array(enemies)
			
			return _units_to_cells(grid, all_units)
		Enums.AreaOfEffect.REMOTE:
			# FIXME: The chosen cells change every time this method is called
			# So when an enemy evaluates a certain skill, the target will change
			# by the time they actually use it
			var shuffled_enemies: Array = enemies.duplicate()
			shuffled_enemies.shuffle()
			
			assert(skill.area_of_effect_size >= 1)
			
			return _units_to_cells(grid, shuffled_enemies.slice(0, skill.area_of_effect_size - 1))
		Enums.AreaOfEffect.RANDOM:
			var shuffled_cells: Array = grid.get_all_cells()
			
			# Note: This can point to same cell as current one
			shuffled_cells.shuffle()
			
			assert(skill.area_of_effect_size >= 1)
			
			return shuffled_cells.slice(0, skill.area_of_effect_size - 1)
		_:
			printerr("Area of effect is not implemented, can't find area: ", skill.area_of_effect)
			return []


# Filter cells to leave only the ones with null units or with targeted units that are
# either allies or enemies depending on the skill type
# Note: If the unit is 2x2 it will be in more than one cell
static func filter_cells(unit: Unit, skill: Skill, target_cells: Array) -> Array:
	# Array<Cell>
	var filtered_cells := []
	
	if skill.is_enemy_targeted():
		for cell in target_cells:
			if cell.unit == null or cell.unit.is_enemy(unit.faction):
				if filtered_cells.find(cell) == -1:
					filtered_cells.push_back(cell)
	else:
		for cell in target_cells:
			if cell.unit == null or cell.unit.is_ally(unit.faction):
				if filtered_cells.find(cell) == -1:
					filtered_cells.push_back(cell)
	
	return filtered_cells


static func _remove_duplicates(target_cells: Array) -> Array:
	# Array<Cell>
	var filtered_cells := []
	
	for cell in target_cells:
		if filtered_cells.find(cell) == -1:
			filtered_cells.push_back(cell)
	
	return filtered_cells


static func _find_horizontal_x_cells(grid: Grid, start_cell: Cell, area_of_effect_size: int) -> Array:
	var targets := []
	
	for x in range(start_cell.coordinates.x - area_of_effect_size, start_cell.coordinates.x + area_of_effect_size + 1):
		var candidate_cell_coordinates := Vector2(x, start_cell.coordinates.y)
		
		if grid._is_in_range(candidate_cell_coordinates):
			targets.push_back(grid.get_cell_from_coordinates(candidate_cell_coordinates))
	
	return targets


static func _find_vertical_x_cells(grid: Grid, start_cell: Cell, area_of_effect_size: int) -> Array:
	var targets := []
	
	for y in range(start_cell.coordinates.y - area_of_effect_size, start_cell.coordinates.y + area_of_effect_size + 1):
		var candidate_cell_coordinates := Vector2(start_cell.coordinates.x, y)
		
		if grid._is_in_range(candidate_cell_coordinates):
			targets.push_back(grid.get_cell_from_coordinates(candidate_cell_coordinates))
	
	return targets


static func _units_to_cells(grid: Grid, units: Array) -> Array:
	var cells := []
	
	# If a unit is 2x2 then add all the cells that it occupies
	for unit in units:
		cells.push_back(grid.get_cell_from_position(unit.position))
	
	return cells

