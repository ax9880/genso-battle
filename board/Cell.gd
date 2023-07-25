extends Area2D

class_name Cell

enum DIRECTION {
	UP,
	DOWN,
	LEFT,
	RIGHT
}


# x,y coordinates in the grid matrix, for convenience.
var coordinates: Vector2 = Vector2.ZERO

# Unit inside this cell.
var unit: Unit = null

# Trap inside this cell
var trap: Trap = null

# Array of Cell. Only valid, non-null neighbors
var neighbors: Array = []

# All neighbors, including invalid ones (those neighbors are set to null)
# {String, nullable Cell}
var all_neighbors: Dictionary = {}


func add_neighbor(neighbor: Cell, direction: int) -> void:
	all_neighbors[direction] = neighbor
	
	if neighbor != null:
		neighbors.push_back(neighbor)


# Gets directional neighbors, for convenience
func get_neighbor(direction: int) -> Cell:
	return all_neighbors[direction]


# Returns Array<Cell>. If there are not enough neighbors, returns an empty array.
# Assumes that the cell is at the top left corner of the area.
func get_cells_in_area(var size: int = 2) -> Array:
	var row_cell: Cell = self
	
	var cells := []
	
	# 0 -> 1
	# 2 -> 3
	
	# 0 -> 1 -> 2
	# 3 -> 4 -> 5
	# 6 -> 7 -> 8
	for _x in range(size):
		cells.push_back(row_cell)
		
		for _y in range(size - 1):
			var column_cell: Cell = row_cell.get_neighbor(DIRECTION.RIGHT)
			
			if column_cell != null:
				cells.push_back(column_cell)
			else:
				break
		
		row_cell = row_cell.get_neighbor(DIRECTION.DOWN)
		
		if row_cell == null:
			break
	
	if cells.size() == size * size:
		return cells
	else:
		return []

