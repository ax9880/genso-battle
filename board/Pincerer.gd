extends Node

class_name Pincerer


class Pincer extends Reference: 
	# Array<Unit>
	var pincering_units: Array
	
	# Array<Unit>
	var pincered_units: Array
	
	# Dictionary<Unit, Array<Array<Unit>>>
	# Where chain_families[unit] consists of all the chains for the given unit (a chain family)
	# And where a chain family consists of lists of chained units (chain). The index of each chain
	# is its chain level. The chain does include the pincering units.
	var chain_families: Dictionary
	
	var pincer_orientation: int = Enums.PincerOrientation.HORIZONTAL
	
	# start position and end position so the pincer highlight
	# uses these positions and it works correctly for 2x2 units
	var start_position: Vector2
	var end_position: Vector2
	
	
	# Size of the pincer (amount of units involved, including pincering and pincered units)
	func size() -> int:
		return pincering_units.size() + pincered_units.size()
	
	
	# A pincer is valid if at least one pincered unit is alive, and all the
	# pincering units are alive.
	# Pincered units can be killed by skills before the pincer is executed.
	# Pincering units can be killed by traps.
	func is_valid() -> bool:
		var is_any_pincered_unit_alive: bool = false
		
		for unit in pincered_units:
			is_any_pincered_unit_alive = is_any_pincered_unit_alive or unit.is_alive()
		
		var is_pincering_units_alive: bool = true
		
		for unit in pincering_units:
			is_pincering_units_alive = is_pincering_units_alive and unit.is_alive()
		
		return is_any_pincered_unit_alive and is_pincering_units_alive


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
			var pincer: Pincer = _check_neighbors_for_pincers(grid, x, y, faction, Cell.DIRECTION.RIGHT, Enums.PincerOrientation.HORIZONTAL)
			
			if pincer == null:
				x += 1
			else:
				x += pincer.size() - 1
				
				_add_pincer(active_unit, leading_pincers, pincers, pincer)
	# Check vertical pincers
	for x in range(grid_width):
		var y: int = grid_height - 1
		
		while y > -1:
			var pincer: Pincer = _check_neighbors_for_pincers(grid, x, y, faction, Cell.DIRECTION.UP, Enums.PincerOrientation.VERTICAL)
			
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
	
	var bottom_left_corner: Cell = grid.get_cell_from_coordinates(Vector2(0, grid_height - 1))
	var bottom_right_corner: Cell = grid.get_cell_from_coordinates(Vector2(grid_width - 1, grid_height - 1))
	var top_left_corner: Cell = grid.get_cell_from_coordinates(Vector2(0, 0))
	var top_right_corner: Cell = grid.get_cell_from_coordinates(Vector2(grid_width - 1, 0))
	
	corner_pincers.push_back(_find_corner_pincer(bottom_left_corner, faction, Enums.PincerOrientation.BOTTOM_LEFT_CORNER))
	corner_pincers.push_back(_find_corner_pincer(bottom_right_corner, faction, Enums.PincerOrientation.BOTTOM_RIGHT_CORNER))
	corner_pincers.push_back(_find_corner_pincer(top_left_corner, faction, Enums.PincerOrientation.TOP_LEFT_CORNER))
	corner_pincers.push_back(_find_corner_pincer(top_right_corner, faction, Enums.PincerOrientation.TOP_RIGHT_CORNER))
	
	for pincer in corner_pincers:
		if pincer != null:
			_add_pincer(active_unit, leading_pincers, pincers, pincer)


func _find_corner_pincer(corner: Cell, faction: int, pincer_orientation: int) -> Pincer:
	var neighbors: Array = corner.neighbors
	
	assert(neighbors.size() == 2, "Corner should have 2 neighbors")
	
	var pincer: Pincer = Pincer.new()
	
	var is_pincer: bool = false
	
	if corner.unit != null and corner.unit.is_enemy(faction):
		for neighbor in neighbors:
			if neighbor.unit != null and neighbor.unit.is_ally(faction) and neighbor.unit.can_act():
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
		pincer.pincer_orientation = pincer_orientation
		
		return pincer
	else:
		return null


# Side effect: Adds a Pincer object to the leading_pincers or pincers arrays
func _add_pincer(active_unit: Unit, leading_pincers: Array, pincers: Array, pincer: Pincer) -> void:
	if pincer == null:
		return
	
	if pincer.pincering_units.find(active_unit) != -1:
		leading_pincers.push_back(pincer)
	else:
		pincers.push_back(pincer)


func _check_neighbors_for_pincers(grid: Grid, start_x: int, start_y: int, faction: int, direction: int, pincer_orientation: int) -> Pincer:
	var cell: Cell = grid.get_cell_from_coordinates(Vector2(start_x, start_y))
	
	var unit = cell.unit
	
	var pincer: Pincer = Pincer.new()
	
	pincer.start_position = cell.position
	
	# Flag enabled if a pincer is detected
	var is_pincer := false
	
	if unit != null and unit.can_act() and unit.is_ally(faction):
		# Start unit
		pincer.pincering_units.push_back(unit)
		
		var neighbor: Cell = cell.get_neighbor(direction)
		
		while neighbor != null:
			var next_unit = neighbor.unit
			
			if next_unit == null:
				# No unit, so we can't make a pincer
				break
			elif next_unit.is_enemy(faction):
				# Is an enemy
				
				# Check if the unit has not been added before, to avoid adding
				# 2x2 units twice
				if not pincer.pincered_units.has(next_unit):
					pincer.pincered_units.push_back(next_unit)
				
				neighbor = neighbor.get_neighbor(direction)
			else:
				# Is an ally
				# Last unit added to list was an enemy
				if (not pincer.pincered_units.empty()) and pincer.pincered_units.back().is_enemy(faction) and next_unit.can_act():
					print("Found pincer!")
					
					is_pincer = true
					
					# End unit
					pincer.pincering_units.push_back(next_unit)
					
					pincer.end_position = neighbor.position
				
				# Else, it's an ally followed by another ally,
				# we can't make a pincer. Either way you have to break
				
				break
	
	if is_pincer:
		assert(pincer.pincering_units.size() == 2, "Pincer should have 2 pincering/leading units")
		
		pincer.pincer_orientation = pincer_orientation
		
		return pincer
	else:
		return null


# Returns Dictionary<Unit, Array<Array<Unit>>>
func _find_chains(grid: Grid, pincering_units: Array) -> Dictionary:
	var faction: int = pincering_units.front().faction
	
	var chain_families: Dictionary = {}
	
	for pincering_unit in pincering_units:
		assert(pincering_unit != null)
		
		chain_families[pincering_unit] = []
	
	for pincering_unit in pincering_units:
		var cell: Cell = grid.get_cell_from_position(pincering_unit.position)
		
		_find_chain(cell, Cell.DIRECTION.RIGHT, chain_families, faction)
		_find_chain(cell, Cell.DIRECTION.LEFT, chain_families, faction)
		_find_chain(cell, Cell.DIRECTION.UP, chain_families, faction)
		_find_chain(cell, Cell.DIRECTION.DOWN, chain_families, faction)
	
	return chain_families


# Finds a chain from a given cell
func _find_chain(cell: Cell, direction: int, chain_families: Dictionary, faction: int) -> void:
	var neighbor = cell.get_neighbor(direction)
	
	var chain_level: int = 0
	
	while(neighbor != null):
		var chained_unit: Unit = neighbor.unit
		
		if chained_unit != null:
			if chained_unit.is_ally(faction) and chained_unit.can_act():
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
	
