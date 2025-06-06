class_name Pusher
extends Node
# Pushes a unit to an appropriate free cell. Units can be pushed by skills,
# by an enemy that appears in the same cell, or when a 2x2 unit moves into
# their same cell


# Dictionary<Direction, Direction>
const OPPOSITE_DIRECTION := {
	Cell.DIRECTION.UP: Cell.DIRECTION.DOWN,
	Cell.DIRECTION.DOWN: Cell.DIRECTION.UP,
	Cell.DIRECTION.RIGHT: Cell.DIRECTION.LEFT,
	Cell.DIRECTION.LEFT: Cell.DIRECTION.RIGHT,
}


# Pushes a unit in the pushed unit cell in a direction that depends from the
# incoming cell
func push_unit(incoming_cell: Cell, pushed_unit_cell: Cell) -> void:
	if pushed_unit_cell.unit == null or pushed_unit_cell.unit.is2x2():
		return
	
	var direction: int = _get_direction(incoming_cell.coordinates, pushed_unit_cell.coordinates)
	var initial_direction: int = direction
	
	var cell_to_move_to: Cell = pushed_unit_cell.get_neighbor(direction)
	
	# If the cell is null, pick another one
	# Move just one cell
	while not _is_cell_free(cell_to_move_to):
		direction = _get_next_direction(direction)
		
		if direction == initial_direction:
			cell_to_move_to = null
			
			break
		else:
			cell_to_move_to = pushed_unit_cell.get_neighbor(direction)
	
	if cell_to_move_to == null:
		cell_to_move_to = _find_closest_free_cell(pushed_unit_cell)
		
		print("Failed to find a free neighboring cell. Searched for a free cell using BFS. Moving to ", cell_to_move_to.coordinates)
	
	if cell_to_move_to == null:
		printerr("Failed to a free cell in the entire grid")
	else:
		assert(cell_to_move_to.unit == null)
		
		var unit: Unit = pushed_unit_cell.unit
		
		pushed_unit_cell.unit = null
		cell_to_move_to.unit = unit
		
		unit.push_to_cell(cell_to_move_to.position)
		
		if cell_to_move_to.trap != null:
			cell_to_move_to.trap.activate(unit)


# Searches for the closest free cell in the grid
func _find_closest_free_cell(start_cell: Cell) -> Cell:
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
