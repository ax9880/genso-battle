extends Area2D

class_name CellArea2D

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

# Array of CellArea2D. Only valid, non-null neighbors
var neighbors: Array = []

# All neighbors, including invalid ones (those neighbors are set to null)
# {String, nullable CellArea2D}
var all_neighbors: Dictionary = {}


func add_neighbor(neighbor: CellArea2D, direction: int) -> void:
	all_neighbors[direction] = neighbor
	
	if neighbor != null:
		neighbors.push_back(neighbor)


# Gets directional neighbors, for convenience
func get_neighbor(direction: int) -> CellArea2D:
	return all_neighbors[direction]
