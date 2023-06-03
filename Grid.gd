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


# Bugs to fix:
# [x] Tunneling
# [-] Dropping in same tile as unit
# [-] Unit sometimes dropped but then it can't be swapped
func _on_cell_body_exited(area: Area2D, cell: CellArea2D) -> void:
	cell.modulate = Color.white
	
	var active_unit = area.get_unit()
	
	if cell.unit != active_unit:
		
		pass
	
	var _is_present: bool = active_unit_entered_cells.erase(cell.name)
	
	var selected_cell: CellArea2D = _find_closest_cell(active_unit.position)
	
	if selected_cell != null:
		# TODO: If there's an enemy in the selected cell then don't do this assignment
		if active_unit_last_valid_cell != active_unit_current_cell:
			active_unit_last_valid_cell = active_unit_current_cell
		
		active_unit_current_cell = selected_cell
		
		print("Left %s and entered %s" % [active_unit_last_valid_cell.coordinates, selected_cell.coordinates])
		
		if selected_cell.coordinates.distance_to(active_unit_last_valid_cell.coordinates) > 1.9:
			active_unit_last_valid_cell.modulate = Color.red
			print("Warning! Jumped more than 1 tile")
		
		var unit_to_swap: Node2D = active_unit_current_cell.unit
		
		_swap_units(active_unit, unit_to_swap, active_unit_current_cell, active_unit_last_valid_cell)


func _on_Unit_picked_up(unit: Node2D, unit_position: Vector2) -> void:
	var cell_coordinates := _get_cell(unit_position)
	
	active_unit_current_cell = grid[cell_coordinates.x][cell_coordinates.y]
	active_unit_last_valid_cell = active_unit_current_cell
	active_unit_entered_cells.clear()
	
	for other_unit in $Units.get_children():
		if other_unit != unit:
			other_unit.disable_selection_area()


func _find_closest_cell(unit_position: Vector2) -> CellArea2D:
	var minimum_distance: float = 1000000.0
	var selected_cell: CellArea2D = null
	
	for entered_cell in active_unit_entered_cells.values():
		var distance_squared: float = unit_position.distance_squared_to(entered_cell.position)
		
		if distance_squared < minimum_distance: # and cell does not contain an enemy unit (just in case)
			minimum_distance = distance_squared
			selected_cell = entered_cell
	
	return selected_cell


func _swap_units(active_unit: Node2D, unit_to_swap: Node2D, next_active_cell: CellArea2D, last_valid_cell: CellArea2D) -> void:
	next_active_cell.unit = active_unit
	last_valid_cell.unit = unit_to_swap
	
	print("Swapped from %s to %s" % [next_active_cell.coordinates, last_valid_cell.coordinates])
	
	if unit_to_swap != null and active_unit != unit_to_swap:
		unit_to_swap.move_to_new_cell(last_valid_cell.position)


func _on_Unit_released(unit: Node2D, unit_position: Vector2) -> void:
	var cell_origin: Vector2 = Vector2.ZERO
	
	var selected_cell: CellArea2D = _find_closest_cell(unit.position)
	
	# FIXME: The other branches may not be necessary
	# The null check may not be necessary either
	if selected_cell != null:
		if selected_cell.unit == null or selected_cell.unit == unit:
			active_unit_current_cell.unit = null
			selected_cell.unit = unit
			cell_origin = selected_cell.position
		else:
			# TODO: If ally, then swap
			# Else, pick the last valid cell
			
			# Now, if the cell is not null but there is an ally, swap them
			_swap_units(unit, selected_cell.unit, selected_cell, active_unit_current_cell)
			
			cell_origin = selected_cell.position
	elif active_unit_current_cell.unit == null:
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
	
	for other_unit in $Units.get_children():
		other_unit.enable_selection_area()


# Returns the x, y coordinates of a cell (whole numbers)
func _get_cell(unit_position: Vector2) -> Vector2:
	return Vector2(floor(unit_position.x / tilesize), floor(unit_position.y / tilesize))


func _cell_coordinates_to_cell_origin(cell_coordinates: Vector2) -> Vector2:
	return Vector2(cell_coordinates.x * tilesize + half_tilesize + tile_offset, cell_coordinates.y * tilesize + + half_tilesize + tile_offset)
