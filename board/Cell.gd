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
