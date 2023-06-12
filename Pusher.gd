extends Node

# Dictionary<Direction, Direction>
const OPPOSITE_DIRECTION := {
	Cell.DIRECTION.UP: Cell.DIRECTION.DOWN,
	Cell.DIRECTION.DOWN: Cell.DIRECTION.UP,
	Cell.DIRECTION.RIGHT: Cell.DIRECTION.LEFT,
	Cell.DIRECTION.LEFT: Cell.DIRECTION.RIGHT,
}


func push_unit(grid: Grid, incoming_cell: Cell, pushed_unit_cell: Cell) -> void:
	if pushed_unit_cell.unit != null:
		var direction: int = _get_direction(incoming_cell.coordinates, pushed_unit_cell.coordinates)
		
		var cell_to_move_to: Cell = pushed_unit_cell.get_neighbor(direction)
		
		var initial_direction: int = direction
		
		# If the cell is null, pick another one
		# Move just one cell
		while not _is_cell_free(cell_to_move_to):
			direction = _get_next_direction(direction)
			
			if direction == initial_direction:
				print("Failed to find a suitable cell to move to in surrounding cells")
				
				break
				# TODO: Use BFS search to find the closest free cell
			else:
				cell_to_move_to = pushed_unit_cell.get_neighbor(direction)
		
		if cell_to_move_to == null:
			print("Failed to find a free neighboring cell. Searching for a free cell using BFS")
			
			cell_to_move_to = _find_first_free_cell(pushed_unit_cell)
		
		if cell_to_move_to == null:
			printerr("Failed to a free cell in the entire grid")
		else:
			var unit: Unit = pushed_unit_cell.unit
			
			pushed_unit_cell.unit = null
			cell_to_move_to.unit = unit
			
			unit.push_to_cell(cell_to_move_to.position)


func _find_first_free_cell(start_cell: Cell) -> Cell:
	var queue := []
	
	queue.push_back(start_cell)
	
	# Dictionary<Cell, bool>
	var discovered_dict := {}
	
	while not queue.empty():
		var node: Cell = queue.pop_front()
		
		# Flag as discovered
		discovered_dict[node] = true
		
		for neighbor in node.neighbors:
			if not discovered_dict.has(neighbor):
				if _is_cell_free(neighbor):
					return neighbor
				else:
					queue.push_back(neighbor)
	
	return null


# Returns Direction enum
func _get_direction(start_coordinates: Vector2, end_coordinates: Vector2) -> int:
	var end_to_start: Vector2 = end_coordinates - start_coordinates
	
	if is_zero_approx(end_to_start.y):
		if end_to_start.x < 0:
			return Cell.DIRECTION.LEFT
		else:
			return Cell.DIRECTION.RIGHT
	else:
		if end_to_start.y < 0:
			return Cell.DIRECTION.UP
		else:
			return Cell.DIRECTION.DOWN


# Gets the next direction in clockwise order
func _get_next_direction(direction: int) -> int:
	match(direction):
		Cell.DIRECTION.UP:
			return Cell.DIRECTION.RIGHT
		Cell.DIRECTION.RIGHT:
			return Cell.DIRECTION.DOWN
		Cell.DIRECTION.DOWN:
			return Cell.DIRECTION.LEFT
		Cell.DIRECTION.LEFT:
			return Cell.DIRECTION.UP
		_:
			return Cell.DIRECTION.UP


func _is_cell_free(cell: Cell) -> bool:
	return cell != null and cell.unit == null
