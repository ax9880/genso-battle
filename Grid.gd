extends Node2D

class_name Grid


class Attack extends Reference:
	var targeted_units: Array = []
	var attacking_unit: Unit
	
	# When in a chain
	var pincering_unit: Unit


export var tilesize: float = 100.0
export var tile_offset: float = 0.0

export var grid_width: int = 6
export var grid_height: int = 8

export(PackedScene) var cell_packed_scene: PackedScene = null

onready var half_tilesize: float = tilesize / 2.0

var active_unit_current_cell: CellArea2D = null
var active_unit_last_valid_cell: CellArea2D = null

# String (node name): CellArea2D
var active_unit_entered_cells := {}

var grid := []

var has_active_unit_exited_cell: bool = false

var enemy_queue := []

# Array<Array<Unit>>
# Where each list consists of start unit + ... pincered units ... + end unit
var pincer_queue := []

var attack_queue := []

var skill_queue := []
var heal_queue := []


func _ready() -> void:
	_initialize_grid()
	
	_assign_units_to_cells()
	_assign_enemies_to_cells()
	
	_start_player_turn()


# Create the grid matrix and populate it with cell objects.
# Connect body enter and exit signals.
func _initialize_grid() -> void:
	for x in range(grid_width):
		grid.append([])
		grid[x].resize(grid_height)
		
		# For each column:
		for y in range(grid_height):
			grid[x][y] = _build_cell(x, y)
	
	# Populate cell neighbors
	for x in range(grid_width):
		for y in range(grid_height):
			var cell: CellArea2D = grid[x][y]
			
			_set_neighbors(cell)


func _build_cell(x_position: float, y_position: float) -> CellArea2D:
	var cell: CellArea2D = cell_packed_scene.instance()
	
	$Cells.add_child(cell)
	
	var cell_coordinates := Vector2(x_position, y_position)
	cell.position = _cell_coordinates_to_cell_origin(cell_coordinates)
	cell.coordinates = cell_coordinates
	
	cell.connect("area_entered", self, "_on_CellArea2D_area_entered", [cell])
	cell.connect("area_exited", self, "_on_CellArea2D_area_exited", [cell])
	
	return cell


func _assign_units_to_cells() -> void:
	for unit in $Units.get_children():
		_assign_unit_to_cell(unit)
		
		unit.connect("picked_up", self, "_on_Unit_picked_up")
		unit.connect("released", self, "_on_Unit_released")
		unit.connect("snapped_to_grid", self, "_on_Unit_snapped_to_grid")
		
		unit.faction = Unit.PLAYER_FACTION


func _assign_enemies_to_cells() -> void:
	for enemy in $Enemies.get_children():
		_assign_unit_to_cell(enemy)
		
		enemy.connect("action_done", self, "_on_Enemy_action_done")
		enemy.connect("started_moving", self, "_on_Enemy_started_moving")
		
		enemy.faction = Unit.ENEMY_FACTION


func _assign_unit_to_cell(unit: Unit) -> void:
	var cell_coordinates: Vector2 = _get_cell_coordinates(unit.position)
	
	unit.position = _cell_coordinates_to_cell_origin(cell_coordinates)
	
	_get_cell_from_coordinates(cell_coordinates).unit = unit


func _start_player_turn() -> void:
	for unit in $Units.get_children():
		unit.enable_selection_area()


func _start_enemy_turn() -> void:
	for unit in $Units.get_children():
		unit.disable_selection_area()
	
	# enemy turn starts right away, there's no animation
	# enqueue enemies
	# decrease turn counter
	# if counter is zero, then move
	# after AI made its move, check for attacks
	# after that, decrease the counter of the next enemy
	# when the queue is empty, start player turn
	for enemy in $Enemies.get_children():
		enemy_queue.push_back(enemy)
	
	_update_enemy()


func _update_enemy() -> void:
	if not enemy_queue.empty():
		enemy_queue.pop_front().act(self)
	else:
		_start_player_turn()


func _on_CellArea2D_area_entered(_area: Area2D, cell: CellArea2D) -> void:
	active_unit_entered_cells[cell.name] = cell
	
	cell.modulate = Color.red


# Bugs to fix:
# [x] Tunneling
# [x] Dropping in same tile as unit
# [-] Unit sometimes dropped but then it can't be swapped
func _on_CellArea2D_area_exited(area: Area2D, cell: CellArea2D) -> void:
	cell.modulate = Color.white
	
	var active_unit = area.get_unit()
	
	if active_unit.is_snapping():
		return
	
	var _is_present: bool = active_unit_entered_cells.erase(cell.name)
	
	var selected_cell: CellArea2D = _find_closest_cell(active_unit.position)
	
	if selected_cell != null:
		# TODO: If there's an enemy in the selected cell then don't do this assignment
		if active_unit_last_valid_cell != active_unit_current_cell:
			active_unit_last_valid_cell = active_unit_current_cell
			
			has_active_unit_exited_cell = true
		
		active_unit_current_cell = selected_cell
		
		print("Left %s and entered %s" % [active_unit_last_valid_cell.coordinates, selected_cell.coordinates])
		
		if selected_cell.coordinates.distance_to(active_unit_last_valid_cell.coordinates) > 1.9:
			active_unit_last_valid_cell.modulate = Color.red
			print("Warning! Jumped more than 1 tile")
		
		_swap_units(active_unit, selected_cell.unit, active_unit_current_cell, active_unit_last_valid_cell)


func _on_Unit_picked_up(unit: Unit) -> void:
	_update_active_unit(unit)
	
	for other_unit in $Units.get_children():
		if other_unit != unit:
			other_unit.disable_selection_area()


func _on_Enemy_started_moving(enemy: Unit) -> void:
	_update_active_unit(enemy)


func _update_active_unit(unit: Unit) -> void:
	# Store this in unit?
	active_unit_current_cell = _get_cell_from_position(unit.position)
	active_unit_last_valid_cell = active_unit_current_cell
	has_active_unit_exited_cell = false
	
	active_unit_entered_cells.clear()


func _find_closest_cell(unit_position: Vector2) -> CellArea2D:
	var minimum_distance: float = 1000000.0
	var selected_cell: CellArea2D = null
	
	for entered_cell in active_unit_entered_cells.values():
		var distance_squared: float = unit_position.distance_squared_to(entered_cell.position)
		
		if distance_squared < minimum_distance: # and cell does not contain an enemy unit (just in case)
			minimum_distance = distance_squared
			selected_cell = entered_cell
	
	return selected_cell


func _swap_units(active_unit: Node2D, unit_to_swap: Node2D, next_active_cell: CellArea2D, last_valid_cell: CellArea2D) -> void:
	if active_unit != unit_to_swap:
		next_active_cell.unit = active_unit
		last_valid_cell.unit = unit_to_swap
	
	if unit_to_swap != null and active_unit != unit_to_swap:
		print("Swapped from %s to %s" % [next_active_cell.coordinates, last_valid_cell.coordinates])
		
		unit_to_swap.move_to_new_cell(last_valid_cell.position)


func _on_Unit_released(unit: Unit) -> void:
	var selected_cell: CellArea2D = _find_closest_cell(unit.position)
	
	# TODO: If ally, then swap
	# Else, pick the last valid cell
	# FIXME: May not work always
	if active_unit_last_valid_cell != selected_cell:
		has_active_unit_exited_cell = true
	
	_swap_units(unit, selected_cell.unit, selected_cell, active_unit_current_cell)
	
	unit.snap_to_grid(selected_cell.position)
	
	# TODO: add drag timer


func _on_Unit_snapped_to_grid(unit: Unit) -> void:
	if has_active_unit_exited_cell:
		# Adds pincers to pincer queue
		_find_pincers(unit, unit.faction)
		
		_attack()
		
		_start_enemy_turn()
	else:
		# Do nothing
		_start_player_turn()


func _on_Enemy_action_done() -> void:
	_update_enemy()


func _find_pincers(active_unit: Unit, faction: int) -> void:
	# List of pincers with the active unit. Horizontal, vertical, and corners
	var leading_pincers := []
	
	# All remaining pincers
	var pincers := []
	
	# Check left to right, down to up
	# from X - 1, step -1, while > -1
	for y in range(grid_height - 1, -1, -1):
		var x: int = 0
		
		while x < grid_width:
			var pincer: Array = _check_neighbors_for_pincers(x, y, faction, CellArea2D.DIRECTION.RIGHT)
			
			if pincer.empty():
				x += 1
			else:
				x += pincer.size()
				
				_add_pincer(active_unit, leading_pincers, pincers, pincer)
	# Check vertical pincers
	for x in range(grid_width):
		var y: int = grid_height - 1
		
		while y > -1:
			var pincer: Array = _check_neighbors_for_pincers(x, y, faction, CellArea2D.DIRECTION.UP)
			
			if pincer.empty():
				y -= 1
			else:
				y -= pincer.size()
				
				_add_pincer(active_unit, leading_pincers, pincers, pincer)
	
	# Check corners
	_find_corner_pincers(active_unit, leading_pincers, pincers, faction)
	
	pincer_queue.clear()
	
	pincer_queue.append_array(leading_pincers)
	pincer_queue.append_array(pincers)


func _find_corner_pincers(active_unit: Unit, leading_pincers: Array, pincers: Array, faction: int) -> void:
	var corner_pincers := []
	
	# FIXME: I can skip all this and let the method use the non-null neighbors of the corner
	var down_left_corner: CellArea2D = _get_cell_from_coordinates(Vector2(0, grid_height - 1))
	
	corner_pincers.push_back(_find_corner_pincer(down_left_corner,
		[down_left_corner.get_neighbor(CellArea2D.DIRECTION.RIGHT), down_left_corner.get_neighbor(CellArea2D.DIRECTION.UP)],
		faction))
	
	var down_right_corner: CellArea2D = _get_cell_from_coordinates(Vector2(grid_width - 1, grid_height - 1))
	
	corner_pincers.push_back(_find_corner_pincer(down_right_corner,
		[down_right_corner.get_neighbor(CellArea2D.DIRECTION.LEFT), down_right_corner.get_neighbor(CellArea2D.DIRECTION.UP)],
		faction))
	
	var up_left_corner: CellArea2D = _get_cell_from_coordinates(Vector2(0, 0))
	
	corner_pincers.push_back(_find_corner_pincer(up_left_corner,
		[up_left_corner.get_neighbor(CellArea2D.DIRECTION.RIGHT), up_left_corner.get_neighbor(CellArea2D.DIRECTION.DOWN)],
		faction))

	var up_right_corner: CellArea2D = _get_cell_from_coordinates(Vector2(grid_width - 1, 0))
	
	corner_pincers.push_back(_find_corner_pincer(up_right_corner,
		[up_right_corner.get_neighbor(CellArea2D.DIRECTION.LEFT), up_right_corner.get_neighbor(CellArea2D.DIRECTION.DOWN)],
		faction))
	
	for pincer in corner_pincers:
		if not pincer.empty():
			_add_pincer(active_unit, leading_pincers, pincers, pincer)


func _find_corner_pincer(corner: CellArea2D, neighbors: Array, faction: int) -> Array:
	var pincer = []
	
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
		pincer.push_back(neighbors.front().unit)
		pincer.push_back(corner.unit)
		pincer.push_back(neighbors.back().unit)
	
	if is_pincer:
		return pincer
	else:
		return []


func _add_pincer(active_unit: Unit, leading_pincers: Array, pincers: Array, pincer: Array) -> void:
	if pincer.empty():
		return
	
	if pincer.find(active_unit) != -1:
		leading_pincers.push_back(pincer)
	else:
		pincers.push_back(pincer)


# Returns how much to advance ? Or return the list
func _check_neighbors_for_pincers(start_x: int, start_y: int, faction: int, direction: int) -> Array:
	var cell: CellArea2D = _get_cell_from_coordinates(Vector2(start_x, start_y))
	
	var unit = cell.unit
	
	# List of units, where if it's a valid pincer, the first and last units
	# are the attacking units
	var units := []
	
	# Flag enabled if a pincer is detected
	var is_pincer := false
	
	if unit != null and unit.is_ally(faction):
		units.push_back(unit)
		
		var neighbor: CellArea2D = cell.get_neighbor(direction)
		
		while neighbor != null:
			var next_unit = neighbor.unit
			
			if next_unit == null:
				# No unit, so we can't make a pincer
				break
			elif next_unit.is_enemy(faction):
				# Is an enemy
				units.push_back(next_unit)
				
				neighbor = neighbor.get_neighbor(direction)
			else:
				# Is an ally
				
				# Last unit added to list was an enemy
				if units.back().is_enemy(faction):
					print("Pincer!")
					is_pincer = true
					
					units.push_back(next_unit)
				
				# Else, it's an ally followed by another ally,
				# we can't make a pincer. Either way you have to break
				
				break
	
	if is_pincer:
		return units
	else:
		return []


# Builds an adjacency list with all the nodes that the given unit can visit
# Enemies may block the unit from reaching certain tiles, besides the tiles they
# already occupy
func build_navigation_graph(unit_position: Vector2, faction: int) -> Dictionary:
	var start_cell: CellArea2D = _get_cell_from_position(unit_position)
	
	var queue := []
	
	queue.push_back(start_cell)
	
	# {CellArea2D, bool}
	var discovered_dict := {}
	
	# {CellArea2D, [CellArea2D] (array of cells connected to this cell)}
	# Graph as adjacency list
	var navigation_graph := {}
	
	while not queue.empty():
		var node: CellArea2D = queue.pop_front()
		
		# Initialize adjacency list for the given node
		navigation_graph[node] = []
		
		# Flag as discovered
		discovered_dict[node] = true
		
		for neighbor in node.neighbors:
			if not discovered_dict.has(neighbor):
				if neighbor.unit == null or neighbor.unit.is_ally(faction):
					navigation_graph[node].push_back(neighbor)
					
					queue.push_back(neighbor)
	
	return navigation_graph


func _set_neighbors(node: CellArea2D) -> void:
	var cell_coordinates: Vector2 = node.coordinates
	
	_set_neighbor(node, Vector2(cell_coordinates.x, cell_coordinates.y - 1), CellArea2D.DIRECTION.UP)
	_set_neighbor(node, Vector2(cell_coordinates.x, cell_coordinates.y + 1), CellArea2D.DIRECTION.DOWN)
	_set_neighbor(node, Vector2(cell_coordinates.x + 1, cell_coordinates.y), CellArea2D.DIRECTION.RIGHT)
	_set_neighbor(node, Vector2(cell_coordinates.x - 1, cell_coordinates.y), CellArea2D.DIRECTION.LEFT)


func _set_neighbor(cell: CellArea2D, neighbor_coordinates: Vector2, direction: int) -> void:
	var neighbor: CellArea2D = null
	
	if _is_in_range(neighbor_coordinates):
		neighbor = _get_cell_from_coordinates(neighbor_coordinates)
	
	cell.add_neighbor(neighbor, direction)


func find_path(navigation_graph: Dictionary, unit_position: Vector2, target_cell: CellArea2D) -> Array:
	# TODO: when planning for chaining, some tiles have to be avoided
	# and the path has to be split
	var start_cell: CellArea2D = _get_cell_from_position(unit_position)
	
	# build A Star graph?
	
	# {CellArea2D, bool}
	var discovered_dict := {}
	
	# {CellArea2D, CellArea2D}
	var parent_dict := {}
	
	var queue := []
	queue.push_back(start_cell)
	
	parent_dict[start_cell] = null
	# Array of target cells
	# and array/dict of excluded cells?
	
	# Breadth-first search (again)
	while not queue.empty():
		var node: CellArea2D = queue.pop_front()
		
		# Flag as discovered
		discovered_dict[node] = true
		
		for neighbor in navigation_graph[node]:
			if not discovered_dict.has(neighbor):
				queue.push_back(neighbor)
				
				parent_dict[neighbor] = node
	
	# Array of CellArea2D
	var path := []
	
	if parent_dict.has(target_cell):
		var node_parent = parent_dict[target_cell]
		
		while node_parent != null:
			path.push_front(node_parent.position)
			node_parent = parent_dict[node_parent]
	
	return path


func _attack() -> void:
	var pincer = pincer_queue.pop_front()
	
	if pincer != null:
		# play pincer animation
		
		#_evaluate_pincer()
		
		var chain_families: Dictionary = _find_chains(pincer)
		
		_queue_attacks(pincer, chain_families)
	else:
		# finish turn
		# but whose turn?
		pass


func _find_chains(pincer: Array) -> Dictionary:
	var start_cell: CellArea2D = _get_cell_from_position(pincer.front().position)
	var end_cell: CellArea2D = _get_cell_from_position(pincer.back().position)
	
	var faction: int = start_cell.unit.faction
	
	# It could be a list instead of a dictionary
	# Dict<Unit, List<List<Unit>>
	var chain_families: Dictionary = {}
	
	chain_families[start_cell.unit] = []
	chain_families[end_cell.unit] = []
	
	_find_chain(start_cell, CellArea2D.DIRECTION.RIGHT, chain_families, faction)
	_find_chain(start_cell, CellArea2D.DIRECTION.LEFT, chain_families, faction)
	_find_chain(start_cell, CellArea2D.DIRECTION.UP, chain_families, faction)
	_find_chain(start_cell, CellArea2D.DIRECTION.DOWN, chain_families, faction)
	
	_find_chain(end_cell, CellArea2D.DIRECTION.RIGHT, chain_families, faction)
	_find_chain(end_cell, CellArea2D.DIRECTION.LEFT, chain_families, faction)
	_find_chain(end_cell, CellArea2D.DIRECTION.UP, chain_families, faction)
	_find_chain(end_cell, CellArea2D.DIRECTION.DOWN, chain_families, faction)
	
	return chain_families


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
				
				var is_in_any_chain := false
				
				for cell_chains in chain_families.values():
					for c in cell_chains:
						if c.find(chained_unit) != -1:
							is_in_any_chain = true
				
				if not is_in_any_chain:
					chain_level += 1
					
					chain.push_back(chained_unit)
			else:
				break
		
		neighbor = neighbor.get_neighbor(direction)


func _queue_attacks(pincer: Array, chain_families: Dictionary) -> void:
	var start_unit: Unit = pincer.front()
	var end_unit: Unit = pincer.back()
	
	var targeted_units = pincer.slice(1, pincer.size() - 2)
	
	attack_queue.clear()
	
	_queue_attack(attack_queue, targeted_units, start_unit)
	_queue_attack(attack_queue, targeted_units, end_unit)
	
	# Or front and back unit, might be clearer
	var start_unit_chains = chain_families[pincer.front()]
	var end_unit_chains = chain_families[pincer.back()]
	
	_queue_chain_attacks(attack_queue, start_unit_chains, targeted_units, start_unit)
	_queue_chain_attacks(attack_queue, end_unit_chains, targeted_units, end_unit)
	
	print(attack_queue.size())


func _queue_attack(queue: Array, targeted_units: Array, attacking_unit: Unit, pincering_unit: Unit = null) -> void:
	var attack: Attack = Attack.new()
	
	attack.targeted_units = targeted_units
	attack.attacking_unit = attacking_unit
	attack.pincering_unit = null
	
	queue.push_back(attack)


func _queue_chain_attacks(queue: Array, chains: Array, targeted_units: Array, pincering_unit: Unit) -> void:
	for chain in chains:
		for unit in chain:
			_queue_attack(attack_queue, targeted_units, unit, pincering_unit)


## Grid utils

func _is_in_range(cell_coordinates: Vector2) -> bool:
	if cell_coordinates.x < 0 or cell_coordinates.x >= grid_width:
		return false
	elif cell_coordinates.y < 0 or cell_coordinates.y >= grid_height:
		return false
	else:
		return true


# Returns the x, y coordinates of a cell (whole numbers)
func _get_cell_coordinates(unit_position: Vector2) -> Vector2:
	return Vector2(floor(unit_position.x / tilesize), floor(unit_position.y / tilesize))


func _get_cell_from_position(unit_position: Vector2) -> CellArea2D:
	var cell_coordinates := _get_cell_coordinates(unit_position)
	
	return _get_cell_from_coordinates(cell_coordinates)


func _get_cell_from_coordinates(cell_coordinates: Vector2) -> CellArea2D:
	return grid[cell_coordinates.x][cell_coordinates.y]


func _cell_coordinates_to_cell_origin(cell_coordinates: Vector2) -> Vector2:
	return Vector2(cell_coordinates.x * tilesize + half_tilesize + tile_offset, cell_coordinates.y * tilesize + + half_tilesize + tile_offset)
