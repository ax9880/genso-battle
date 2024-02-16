extends Reference

class_name PossiblePincer


var start_cell: Cell = null
var end_cell: Cell = null

var units_pincered_count: int = 0

var ally: Unit = null

var start_cell_path_length: int = 0
var end_cell_path_length: int = 0

# Path that the unit should take to reach the end cell.
var path_to_end_cell: Array = []

# Array of cells that have the pincered units
var pincered_cells: Array = []


func equals(other: PossiblePincer) -> bool:
	return (start_cell == other.start_cell and end_cell == other.end_cell) or \
			(start_cell == other.end_cell and end_cell == other.start_cell)
