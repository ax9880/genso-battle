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
	_assign_units_to_cells()


# Create the grid matrix and populate it with cell objects.
# Connect body enter and exit signals.
func _initialize_grid() -> void:
	for x in range(grid_width):
		grid.append([])
		grid[x].resize(grid_height)
		
		# For each column:
		for y in range(grid_height):
			grid[x][y] = _build_cell(x, y)


func _build_cell(x_position: float, y_position: float) -> CellArea2D:
	var cell_coordinates := Vector2(x_position, y_position)
	var cell_origin: Vector2 = _cell_coordinates_to_cell_origin(cell_coordinates)
	
	var cell: CellArea2D = cell_packed_scene.instance()
	$Cells.add_child(cell)
	
	cell.position = cell_origin
	cell.coordinates = cell_coordinates
	
	cell.connect("area_entered", self, "_on_cell_body_entered", [cell])
	cell.connect("area_exited", self, "_on_cell_body_exited", [cell])
	
	return cell


func _assign_units_to_cells() -> void:
	for unit in $Units.get_children():
		var cell_coordinates: Vector2 = _get_cell(unit.position)
		
		unit.position = _cell_coordinates_to_cell_origin(cell_coordinates)
		
		grid[cell_coordinates.x][cell_coordinates.y].unit = unit
		
		unit.connect("picked_up", self, "_on_Unit_picked_up")
		unit.connect("released", self, "_on_Unit_released")


func _on_cell_body_entered(_area: Area2D, cell: CellArea2D) -> void:
	active_unit_entered_cells[cell.name] = cell
	
	cell.modulate = Color.red


func _on_cell_body_exited(area: Area2D, cell: CellArea2D) -> void:
	cell.modulate = Color.white
	
	var active_unit = area.get_unit()
	
	if cell.unit != active_unit:
		
		pass
	
	var _is_present: bool = active_unit_entered_cells.erase(cell.name)
	
	var minimum_distance: float = 1000000.0
	var selected_cell: CellArea2D = null
	
	# Sets the currently active area to the cell closest to the unit's origin
	for entered_cell in active_unit_entered_cells.values():
		var distance_squared: float = active_unit.position.distance_squared_to(entered_cell.position)
		
		if distance_squared < minimum_distance: # and cell does not contain an enemy unit (just in case)
			minimum_distance = distance_squared
			selected_cell = entered_cell
	
	if selected_cell != null:
		# TODO: If there's an enemy in the selected cell then don't do this assignment
		if active_unit_last_valid_cell != active_unit_current_cell:
			active_unit_last_valid_cell = active_unit_current_cell
		
		active_unit_current_cell = selected_cell
		
		#print("Left %s and entered %s" % [active_unit_last_valid_cell.coordinates, selected_cell.coordinates])
		if selected_cell.coordinates.distance_to(active_unit_last_valid_cell.coordinates) > 1.9:
			active_unit_last_valid_cell.modulate = Color.red
			print("Warning! Jumped more than 1 tile")
		
		var swapped_unit: Node2D = active_unit_current_cell.unit
		
		if swapped_unit != null and (active_unit != swapped_unit):
			active_unit_last_valid_cell.unit = swapped_unit
			active_unit_current_cell.unit = active_unit
			
			print("Swapped from %s to %s" % [active_unit_current_cell.coordinates, active_unit_last_valid_cell.coordinates])
			
			if active_unit_current_cell.coordinates.distance_to(active_unit_last_valid_cell.coordinates) > 1.9:
				#print("Warning! Jumped more than 1 tile")
				pass
			
			swapped_unit.move_to_new_cell(active_unit_last_valid_cell.position)
		else:
			active_unit_last_valid_cell.unit = null
			active_unit_current_cell.unit = active_unit


func _on_Unit_picked_up(unit: Node2D, unit_position: Vector2) -> void:
	var cell_coordinates := _get_cell(unit_position)
	
	active_unit_current_cell = grid[cell_coordinates.x][cell_coordinates.y]
	active_unit_last_valid_cell = active_unit_current_cell
	active_unit_entered_cells.clear()


func _on_Unit_released(unit: Node2D, unit_position: Vector2) -> void:
	# TODO: snap to active area or last active area if that one is not valid
	#var cell_coordinates: Vector2 = _get_cell(active_unit_current_cell.position)
	#print("Cell: (", cell_coordinates.x, ", ", cell_coordinates.y, ")")
	
	var cell_origin: Vector2 = Vector2.ZERO
	
	# Active cell is available
	if active_unit_current_cell.unit == null or active_unit_current_cell.unit == unit:
		active_unit_last_valid_cell.unit = null
		active_unit_current_cell.unit = unit
		
		cell_origin = active_unit_current_cell.position
	else:
		# If there's a unit there then go to the last valid position
		# Although you should have swapped with a unit before that happens...
		cell_origin = active_unit_last_valid_cell.position
		
		if active_unit_current_cell.unit == unit:
			active_unit_current_cell.unit = null
		
		active_unit_last_valid_cell.unit = unit
	
	unit.snap_to_grid(cell_origin)


# Returns the x, y coordinates of a cell (whole numbers)
func _get_cell(unit_position: Vector2) -> Vector2:
	return Vector2(floor(unit_position.x / tilesize), floor(unit_position.y / tilesize))


func _cell_coordinates_to_cell_origin(cell_coordinates: Vector2) -> Vector2:
	return Vector2(cell_coordinates.x * tilesize + half_tilesize + tile_offset, cell_coordinates.y * tilesize + + half_tilesize + tile_offset)
