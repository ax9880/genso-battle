extends Node2D

class_name Grid


const PLAYER_GROUP := "player"
const ENEMY_GROUP := "enemy"


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
		
		unit.add_to_group(PLAYER_GROUP)


func _assign_enemies_to_cells() -> void:
	for enemy in $Enemies.get_children():
		_assign_unit_to_cell(enemy)
		
		enemy.connect("action_done", self, "_on_Enemy_action_done")
		enemy.connect("started_moving", self, "_on_Enemy_started_moving")
		
		enemy.add_to_group(ENEMY_GROUP)


func _assign_unit_to_cell(unit: Unit) -> void:
	var cell_coordinates: Vector2 = _get_cell(unit.position)
	
	unit.position = _cell_coordinates_to_cell_origin(cell_coordinates)
	
	grid[cell_coordinates.x][cell_coordinates.y].unit = unit


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
	var cell_coordinates: Vector2 = _get_cell(unit.position)
	
	# Store this in unit?
	active_unit_current_cell = grid[cell_coordinates.x][cell_coordinates.y]
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
		_check_pincers(unit, PLAYER_GROUP)
		
		_start_enemy_turn()
	else:
		# Do nothing
		_start_player_turn()


func _on_Enemy_action_done() -> void:
	_update_enemy()


func _check_pincers(active_unit: Unit, group: String) -> void:
	# Check left to right, down to up
	
	# from X - 1, step -1, while > -1
	for y in range(grid_height - 1, -1, -1):
		var x: int = 0
		
		while x < grid_width:
			var cell: CellArea2D = grid[x][y]
			
			var unit = cell.unit
			
			if unit != null and unit.is_in_group(group):
				var units := []
				
				units.push_back(unit)
				
				var right_neighbor: CellArea2D = cell.right_neighbor 
				
				while right_neighbor != null:
					var next_unit = right_neighbor.unit
					
					if next_unit == null:
						break
					elif not next_unit.is_in_group(group):
						# Is an enemy
						units.push_back(next_unit)
						
						right_neighbor = right_neighbor.right_neighbor
					else:
						# Is an ally
						
						# Last unit added to list was an enemy
						if not units.back().is_in_group(group):
							print("Pincer!")
							
							units.push_back(next_unit)
							
							x += units.size() - 1
							break
						else:
							break
			
			x += 1
	
	# Check vertical pincers
	
	# Check corners
	
	pass


func build_navigation_graph(unit_position: Vector2, group: String) -> Dictionary:
	var cell_coordinates: Vector2 = _get_cell(unit_position)
	
	var start_cell: CellArea2D = grid[cell_coordinates.x][cell_coordinates.y]
	
	# processed
	# discovered
	# parent
	
	var max_vertices: int = grid_width * grid_height
	
	var processed := []
	var discovered := []
	var parent := []
	
	processed.resize(max_vertices)
	discovered.resize(max_vertices)
	parent.resize(max_vertices)
	
	for i in range(max_vertices):
		discovered[i] = false
		parent[i] = -1
	
	var queue := []
	
	queue.push_back(start_cell)
	
	# {String, bool}
	var discovered_dict := {}
	
	# {CellArea2D, [CellArea2D] (cells connected to this cell)}
	# Graph as adjacency list
	var navigation_graph := {}
	
	while not queue.empty():
		var node: CellArea2D = queue.pop_front()
		
		navigation_graph[node] = []
		
		# Flag as discovered
		discovered_dict[node.name] = true
		
		for neighbor in node.neighbors:
			if not discovered_dict.has(neighbor.name):
				if neighbor.unit == null or neighbor.unit.is_in_group(group):
					navigation_graph[node].push_back(neighbor)
					
					queue.push_back(neighbor)
	
	return navigation_graph


func _set_neighbors(node: CellArea2D) -> void:
	var cell_coordinates: Vector2 = node.coordinates
	
	var up := Vector2(cell_coordinates.x, cell_coordinates.y - 1)
	var down := Vector2(cell_coordinates.x, cell_coordinates.y + 1)
	var right := Vector2(cell_coordinates.x + 1, cell_coordinates.y)
	var left := Vector2(cell_coordinates.x - 1, cell_coordinates.y)
	
	_set_neighbor(node, up, "up")
	_set_neighbor(node, down, "down")
	_set_neighbor(node, right, "right")
	_set_neighbor(node, left, "left")


func _set_neighbor(cell: CellArea2D, neighbor_position: Vector2, direction: String) -> void:
	var neighbor: CellArea2D = null
	
	if _is_in_range(neighbor_position):
		neighbor = grid[neighbor_position.x][neighbor_position.y]
	
	cell.set(direction + "_neighbor", neighbor)
	
	if neighbor != null:
		cell.neighbors.push_back(neighbor)


func find_path(navigation_graph: Dictionary, unit_position: Vector2, target_cell: CellArea2D) -> Array:
	# TODO: when planning for chaining, some tiles have to be avoided
	# and the path has to be split
	var cell_coordinates: Vector2 = _get_cell(unit_position)
	var start_cell: CellArea2D = grid[cell_coordinates.x][cell_coordinates.y]
	
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


func _is_in_range(cell_coordinates: Vector2) -> bool:
	if cell_coordinates.x < 0 or cell_coordinates.x >= grid_width:
		return false
	elif cell_coordinates.y < 0 or cell_coordinates.y >= grid_height:
		return false
	else:
		return true


# Returns the x, y coordinates of a cell (whole numbers)
# TODO: rename
func _get_cell(unit_position: Vector2) -> Vector2:
	return Vector2(floor(unit_position.x / tilesize), floor(unit_position.y / tilesize))


func _cell_coordinates_to_cell_origin(cell_coordinates: Vector2) -> Vector2:
	return Vector2(cell_coordinates.x * tilesize + half_tilesize + tile_offset, cell_coordinates.y * tilesize + + half_tilesize + tile_offset)
