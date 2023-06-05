extends Node2D

class_name Grid

export var tilesize: float = 100.0
export var tile_offset: float = 0.0

export var width: int = 6
export var height: int = 8

export(PackedScene) var cell_packed_scene: PackedScene = null

onready var half_tilesize: float = tilesize / 2.0

# Array<Array<CellArea2D>>
# Where grid[i] is a row
var grid := []


func _ready() -> void:
	_initialize_grid()


# Create the grid matrix and populate it with cell objects.
# Connect body enter and exit signals.
func _initialize_grid() -> void:
	for x in range(width):
		grid.append([])
		grid[x].resize(height)
		
		# For each column:
		for y in range(height):
			grid[x][y] = _build_cell(x, y)
	
	# Populate cell neighbors
	for x in range(width):
		for y in range(height):
			var cell: CellArea2D = grid[x][y]
			
			_set_neighbors(cell)


func _build_cell(x_position: float, y_position: float) -> CellArea2D:
	var cell: CellArea2D = cell_packed_scene.instance()
	
	$Cells.add_child(cell)
	
	var cell_coordinates := Vector2(x_position, y_position)
	cell.position = cell_coordinates_to_cell_origin(cell_coordinates)
	cell.coordinates = cell_coordinates
	
	return cell


func _set_neighbors(node: CellArea2D) -> void:
	var cell_coordinates: Vector2 = node.coordinates
	
	_set_neighbor(node, Vector2(cell_coordinates.x, cell_coordinates.y - 1), CellArea2D.DIRECTION.UP)
	_set_neighbor(node, Vector2(cell_coordinates.x, cell_coordinates.y + 1), CellArea2D.DIRECTION.DOWN)
	_set_neighbor(node, Vector2(cell_coordinates.x + 1, cell_coordinates.y), CellArea2D.DIRECTION.RIGHT)
	_set_neighbor(node, Vector2(cell_coordinates.x - 1, cell_coordinates.y), CellArea2D.DIRECTION.LEFT)


func _set_neighbor(cell: CellArea2D, neighbor_coordinates: Vector2, direction: int) -> void:
	var neighbor: CellArea2D = null
	
	if _is_in_range(neighbor_coordinates):
		neighbor = get_cell_from_coordinates(neighbor_coordinates)
	
	cell.add_neighbor(neighbor, direction)


func _is_in_range(cell_coordinates: Vector2) -> bool:
	if cell_coordinates.x < 0 or cell_coordinates.x >= width:
		return false
	elif cell_coordinates.y < 0 or cell_coordinates.y >= height:
		return false
	else:
		return true


# Returns the x, y coordinates of a cell (whole numbers)
func get_cell_coordinates(unit_position: Vector2) -> Vector2:
	return Vector2(floor(unit_position.x / tilesize), floor(unit_position.y / tilesize))


func get_cell_from_position(unit_position: Vector2) -> CellArea2D:
	var cell_coordinates := get_cell_coordinates(unit_position)
	
	return get_cell_from_coordinates(cell_coordinates)


func get_cell_from_coordinates(cell_coordinates: Vector2) -> CellArea2D:
	return grid[cell_coordinates.x][cell_coordinates.y]


func cell_coordinates_to_cell_origin(cell_coordinates: Vector2) -> Vector2:
	return Vector2(cell_coordinates.x * tilesize + half_tilesize + tile_offset, cell_coordinates.y * tilesize + + half_tilesize + tile_offset)

