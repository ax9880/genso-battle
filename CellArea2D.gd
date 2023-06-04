extends Area2D

class_name CellArea2D

# x,y coordinates in the grid matrix, for convenience.
var coordinates: Vector2 = Vector2.ZERO

# Unit inside this cell.
var unit: Unit = null

# Array of CellArea2D
var neighbors: Array = []
