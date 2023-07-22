extends Node

class_name BoardUtils


# Builds an adjacency dictionary with all the nodes that the given unit can visit
# Enemies may block the unit from reaching certain tiles, besides the tiles they
# already occupy
static func build_navigation_graph(grid: Grid, unit_position: Vector2, faction: int, movement_range: int) -> Dictionary:
	var start_cell: Cell = grid.get_cell_from_position(unit_position)
	
	var queue := []
	
	queue.push_back(start_cell)
	
	# Dictionary<Cell, bool>
	var discovered_dict := {}
	
	# Dictionary<Cell, Array<Cell> (array of cells connected to this cell)>
	# Graph as adjacency list
	var navigation_graph := {}
	
	while not queue.empty():
		var node: Cell = queue.pop_front()
		
		# Initialize adjacency list for the given node
		navigation_graph[node] = []
		
		# Flag as discovered
		discovered_dict[node] = true
		
		for neighbor in node.neighbors:
			if not discovered_dict.has(neighbor):
				var unit: Unit = neighbor.unit
				
				if unit == null or (unit.is_ally(faction) and not unit.is2x2()):
					# FIXME: Calculate the distance using the shortest path, and
					# use that to find out if you can reach that cell
					if get_distance_to_cell(start_cell, neighbor) <= movement_range:
						navigation_graph[node].push_back(neighbor)
						
						queue.push_back(neighbor)
	
	return navigation_graph


static func get_distance_to_cell(start_cell: Cell, end_cell: Cell) -> float:
	return abs(end_cell.coordinates.x - start_cell.coordinates.x) + abs(end_cell.coordinates.y - start_cell.coordinates.y)


static func find_path(grid: Grid, navigation_graph: Dictionary, unit_position: Vector2, target_cell: Cell) -> Array:
	# TODO: when planning for chaining, some tiles have to be avoided
	# and the path has to be split
	# Array of target cells
	# and array/dict of excluded cells?
	var start_cell: Cell = grid.get_cell_from_position(unit_position)
	
	# Dictionary<Cell, bool>
	var discovered_dict := {}
	
	# Dictionary<Cell, Cell>
	var parent_dict := {}
	
	var queue := []
	queue.push_back(start_cell)
	
	parent_dict[start_cell] = null
	
	# Breadth-first search (again)
	while not queue.empty():
		var node: Cell = queue.pop_front()
		
		# Flag as discovered
		discovered_dict[node] = true
		
		if node == target_cell:
			break
		
		for neighbor in navigation_graph[node]:
			if not discovered_dict.has(neighbor):
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


# Returns Array<Cell>
static func find_area_of_effect_target_cells(var unit_position: Vector2,
		var skill: Skill,
		var grid: Grid,
		var pincered_units: Array = [], # Array<Unit>
		var chain: Array = [], # Array<Unit>, including the pincering unit that started the chain
		var allies: Array = [], # Array<Unit>
		var enemies: Array = [] # Array<Unit>
	) -> Array:
	
	var cell: Cell = grid.get_cell_from_position(unit_position)
	
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
			return [grid.get_cell_from_position(unit_position)]
		Enums.AreaOfEffect.HORIZONTAL_X:
			# TODO: If unit is 2x2 then you have to do this for each cell it occupies
			# and then the cells that it occupies are filtered out
			
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
		_:
			printerr("Area of effect is not implemented, can't find area: ", skill.area_of_effect)
			return []


# Filter cells to leave only the ones with null units or with targeted units that are
# either allies or enemies depending on the skill type
static func filter_cells(unit: Unit, skill: Skill, targeted_cells: Array) -> Array:
	# If the unit is 2x2 it will be in more than one cell, so don't add it twice
	
	# Array<Cell>
	var filtered_cells := []
	
	if skill.is_enemy_targeted():
		for cell in targeted_cells:
			if cell.unit == null or cell.unit.is_enemy(unit.faction):
				if filtered_cells.find(cell) == -1:
					filtered_cells.push_back(cell)
	else:
		for cell in targeted_cells:
			if cell.unit == null or cell.unit.is_ally(unit.faction):
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


static func _units_to_cells(grid, units: Array) -> Array:
	var cells := []
	
	# If a unit is 2x2 then add all the cells that it occupies
	for unit in units:
		cells.push_back(grid.get_cell_from_position(unit.position))
	
	return cells

