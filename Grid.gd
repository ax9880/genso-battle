extends Node2D


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


func _ready() -> void:
	_initialize_grid()


func _initialize_grid() -> void:
	for x in range(grid_width):
		grid.append([])
		grid[x].resize(grid_height)
		
		# For each column:
		for y in range(grid_height):
			grid[x][y] = _build_cell(x, y)
			
			# TODO: detect where units are and add them to the grid / cell


func _initialize_cells() -> void:
	for x in range(grid.size()):
		for y in range(grid[x].size()):
			var cell_origin: Vector2 = _cell_coordinates_to_cell_origin(Vector2(x, y))
			
			var cell = cell_packed_scene.instance()
			add_child(cell)
			cell.position = cell_origin
			
			cell.connect("body_entered", self, "_on_cell_body_entered")
			cell.connect("body_exited", self, "_on_cell_body_exited")


func _build_cell(x_position: float, y_position: float) -> CellArea2D:
	var cell_coordinates := Vector2(x_position, y_position)
	var cell_origin: Vector2 = _cell_coordinates_to_cell_origin(cell_coordinates)
	
	var cell: CellArea2D = cell_packed_scene.instance()
	add_child(cell)
	
	cell.position = cell_origin
	cell.coordinates = cell_coordinates
	
	cell.connect("body_entered", self, "_on_cell_body_entered", [cell])
	cell.connect("body_exited", self, "_on_cell_body_exited", [cell])
	
	return cell


func _on_cell_body_entered(body: Node, cell: CellArea2D) -> void:
	active_unit_entered_cells[cell.name] = cell
	
	cell.modulate = Color.red


func _on_cell_body_exited(body: Node, cell: CellArea2D) -> void:
	cell.modulate = Color.white

	active_unit_entered_cells.erase(cell.name)
	
	var distance = 10000
	var selected_cell = null
	
	for active_cell in active_unit_entered_cells.values():
		if active_cell != null:
			var distance_squared: float = body.position.distance_squared_to(active_cell.position)
			
			if distance_squared < distance:
				distance_squared = distance
				selected_cell = active_cell
	
	if selected_cell != null:
		active_unit_current_cell = selected_cell


func _on_Unit_released(unit: Node2D, unit_position: Vector2) -> void:
	# TODO: snap to active area or last active area if that one is not valid
	var cell_coordinates: Vector2 = _get_cell(unit_position)
	
	print("Cell: (", cell_coordinates.x, ", ", cell_coordinates.y, ")")
	
	var cell_origin := _cell_coordinates_to_cell_origin(cell_coordinates)
	
	unit.snap_to_grid(cell_origin)


func _on_Unit_picked_up(_unit: Node2D, unit_position: Vector2) -> void:
	var cell_coordinates := _get_cell(unit_position)
	
	active_unit_current_cell = grid[cell_coordinates.x][cell_coordinates.y]


# Returns the x, y coordinates of a cell (whole numbers)
func _get_cell(unit_position: Vector2) -> Vector2:
	return Vector2(floor(unit_position.x / tilesize), floor(unit_position.y / tilesize))


func _cell_coordinates_to_cell_origin(cell_coordinates: Vector2) -> Vector2:
	return Vector2(cell_coordinates.x * tilesize + half_tilesize + tile_offset, cell_coordinates.y * tilesize + + half_tilesize + tile_offset)
