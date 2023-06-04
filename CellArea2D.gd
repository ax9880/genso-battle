extends Area2D

class_name CellArea2D

enum DIRECTION {
	UP = 0,
	
	DOWN = 1,
	
	LEFT = 2,
	
	RIGHT = 3
}


# x,y coordinates in the grid matrix, for convenience.
var coordinates: Vector2 = Vector2.ZERO

# Unit inside this cell.
var unit: Unit = null

# Array of CellArea2D
var neighbors: Array = []

# Directional neighbors, for convenience
var up_neighbor: CellArea2D = null
var down_neighbor: CellArea2D = null
var right_neighbor: CellArea2D = null
var left_neighbor: CellArea2D = null
