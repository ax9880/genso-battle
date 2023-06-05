extends Node

class_name Pincerer

class Pincer extends Reference: 
	# Array<Unit>
	var pincering_units: Array
	
	# Array<Unit>
	var pincered_units: Array
	
	# Dictionary<Unit, List<List<Unit>>
	# Where chain_families[unit] consists of all the chains for the given unit
	# And where a chain consists of lists of chained units. The index of each chain
	# is its chain level.
	var chain_families: Dictionary
	
	func size() -> int:
		return pincering_units.size() + pincered_units.size()


var pincer_queue := []


func find_pincers(grid: Grid, active_unit: Unit) -> Array:
	pincer_queue = _find_pincers(grid, active_unit)
	
	# Add the chains to the pincer
	for pincer in pincer_queue:
		pincer.chain_families = _find_chains(grid, pincer.pincering_units)
	
	return pincer_queue


# Finds all pincers, but does not find the chains.
func _find_pincers(grid: Grid, active_unit: Unit) -> Array:
	# List of pincers with the active unit. Horizontal, vertical, and corners
	# Array<Pincer>
	var leading_pincers := []
	
	# All remaining pincers
	# Array<Pincer>
	var pincers := []
	
	var grid_width: int = grid.width
	var grid_height: int = grid.height
	var faction = active_unit.faction
	
	# Check left to right, down to up
	# from X - 1, step -1, while > -1
	for y in range(grid_height - 1, -1, -1):
		var x: int = 0
		
		while x < grid_width:
			var pincer: Pincer = _check_neighbors_for_pincers(grid, x, y, faction, CellArea2D.DIRECTION.RIGHT)
			
			if pincer == null:
				x += 1
			else:
				x += pincer.size() - 1
				
				_add_pincer(active_unit, leading_pincers, pincers, pincer)
	# Check vertical pincers
	for x in range(grid_width):
		var y: int = grid_height - 1
		
		while y > -1:
			var pincer: Pincer = _check_neighbors_for_pincers(grid, x, y, faction, CellArea2D.DIRECTION.UP)
			
			if pincer == null:
				y -= 1
			else:
				y = y - pincer.size() + 1
				
				_add_pincer(active_unit, leading_pincers, pincers, pincer)
	
	# Check corners
	_find_corner_pincers(grid, active_unit, leading_pincers, pincers)
	
	var all_pincers := []
	
	all_pincers.append_array(leading_pincers)
	all_pincers.append_array(pincers)
	
	return all_pincers


func _find_corner_pincers(grid: Grid, active_unit: Unit, leading_pincers: Array, pincers: Array) -> void:
	var corner_pincers := []
	
	var grid_width: int = grid.width
	var grid_height: int = grid.height
	
	var faction: int = active_unit.faction
	
	var down_left_corner: CellArea2D = grid.get_cell_from_coordinates(Vector2(0, grid_height - 1))
	var down_right_corner: CellArea2D = grid.get_cell_from_coordinates(Vector2(grid_width - 1, grid_height - 1))
	var up_left_corner: CellArea2D = grid.get_cell_from_coordinates(Vector2(0, 0))
	var up_right_corner: CellArea2D = grid.get_cell_from_coordinates(Vector2(grid_width - 1, 0))
	
	corner_pincers.push_back(_find_corner_pincer(down_left_corner, faction))
	corner_pincers.push_back(_find_corner_pincer(down_right_corner, faction))
	corner_pincers.push_back(_find_corner_pincer(up_left_corner, faction))
	corner_pincers.push_back(_find_corner_pincer(up_right_corner, faction))
	
	for pincer in corner_pincers:
		if pincer != null:
			_add_pincer(active_unit, leading_pincers, pincers, pincer)


func _find_corner_pincer(corner: CellArea2D, faction: int) -> Pincer:
	var neighbors: Array = corner.neighbors
	
	assert(neighbors.size() == 2)
	
	var pincer: Pincer = Pincer.new()
	
	var is_pincer = false
	
	if corner.unit != null and corner.unit.is_enemy(faction):
		for neighbor in neighbors:
			if neighbor.unit != null and neighbor.unit.is_ally(faction):
				# This _will_ set the flag to true prematurely, before the other
				# neighbor is evaluated, but that's why the flag is set to false
				# in the other branch
				is_pincer = true
			else:
				is_pincer = false
				
				break
	
	if is_pincer:
		for neighbor in neighbors:
			pincer.pincering_units.push_back(neighbor.unit)
		
		pincer.pincered_units.push_back(corner.unit)
	
	if is_pincer:
		return pincer
	else:
		return null


func _add_pincer(active_unit: Unit, leading_pincers: Array, pincers: Array, pincer: Pincer) -> void:
	if pincer == null:
		return
	
	if pincer.pincering_units.find(active_unit) != -1:
		leading_pincers.push_back(pincer)
	else:
		pincers.push_back(pincer)


func _check_neighbors_for_pincers(grid: Grid, start_x: int, start_y: int, faction: int, direction: int) -> Pincer:
	var cell: CellArea2D = grid.get_cell_from_coordinates(Vector2(start_x, start_y))
	
	var unit = cell.unit
	
	var pincer: Pincer = Pincer.new()
	
	# Flag enabled if a pincer is detected
	var is_pincer := false
	
	if unit != null and unit.is_ally(faction):
		# Start unit
		pincer.pincering_units.push_back(unit)
		
		var neighbor: CellArea2D = cell.get_neighbor(direction)
		
		while neighbor != null:
			var next_unit = neighbor.unit
			
			if next_unit == null:
				# No unit, so we can't make a pincer
				break
			elif next_unit.is_enemy(faction):
				# Is an enemy
				pincer.pincered_units.push_back(next_unit)
				
				neighbor = neighbor.get_neighbor(direction)
			else:
				# Is an ally
				# Last unit added to list was an enemy
				if not pincer.pincered_units.empty() and pincer.pincered_units.back().is_enemy(faction):
					print("Found pincer!")
					
					is_pincer = true
					
					# End unit
					pincer.pincering_units.push_back(next_unit)
				
				# Else, it's an ally followed by another ally,
				# we can't make a pincer. Either way you have to break
				
				break
	
	if is_pincer:
		assert(pincer.pincering_units.size() == 2)
		
		return pincer
	else:
		return null


func _find_chains(grid: Grid, pincering_units: Array) -> Dictionary:
	var faction: int = pincering_units.front().faction
	
	var chain_families: Dictionary = {}
	
	for pincering_unit in pincering_units:
		chain_families[pincering_unit] = []
	
	for pincering_unit in pincering_units:
		var cell: CellArea2D = grid.get_cell_from_position(pincering_unit.position)
		
		_find_chain(cell, CellArea2D.DIRECTION.RIGHT, chain_families, faction)
		_find_chain(cell, CellArea2D.DIRECTION.LEFT, chain_families, faction)
		_find_chain(cell, CellArea2D.DIRECTION.UP, chain_families, faction)
		_find_chain(cell, CellArea2D.DIRECTION.DOWN, chain_families, faction)
	
	return chain_families


# Finds a chain from a given cell
func _find_chain(cell: CellArea2D, direction: int, chain_families: Dictionary, faction: int) -> void:
	var neighbor = cell.get_neighbor(direction)
	
	var chain_level: int = 0
	
	while(neighbor != null):
		var chained_unit: Unit = neighbor.unit
		
		if chained_unit != null:
			if chained_unit.is_ally(faction):
				var chains: Array = chain_families[cell.unit]
				
				if chains.size() < chain_level + 1:
					chains.push_back([])
				
				var chain: Array = chains[chain_level]
				
				if not _is_in_any_chain(chained_unit, chain_families):
					chain_level += 1
					
					chain.push_back(chained_unit)
			else:
				break
		
		neighbor = neighbor.get_neighbor(direction)


func _is_in_any_chain(unit: Unit, chain_families: Dictionary) -> bool:
	for chains in chain_families.values():
		for chain in chains:
			if chain.find(unit) != -1:
				return true
	
	return false
	
