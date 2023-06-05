extends Node2D

class_name Board

enum Turn {
	NONE, PLAYER, ENEMY
}

export(PackedScene) var attack_effect_packed_scene: PackedScene = null

onready var grid := $Grid
onready var grid_width: int = grid.width
onready var grid_height: int = grid.height

var active_unit_current_cell: CellArea2D = null
var active_unit_last_valid_cell: CellArea2D = null

# Dictionary<CellArea2D, bool>
var active_unit_entered_cells := {}

var has_active_unit_exited_cell: bool = false

var enemy_queue := []

# Array<Array<Unit>>
# Where each list consists of start unit + ... pincered units ... + end unit
var pincer_queue := []

var skill_queue := []
var heal_queue := []

var current_turn: int = Turn.NONE


func _ready() -> void:
	_initialize_grid()
	
	_assign_units_to_cells()
	_assign_enemies_to_cells()
	
	_start_player_turn()


# Create the grid matrix and populate it with cell objects.
# Connect body enter and exit signals.
func _initialize_grid() -> void:
	_connect_cell_signals()


func _connect_cell_signals() -> void:
	for row in grid.grid:
		for cell in row:
			var _error = cell.connect("area_entered", self, "_on_CellArea2D_area_entered", [cell])
			_error = cell.connect("area_exited", self, "_on_CellArea2D_area_exited", [cell])


func _assign_units_to_cells() -> void:
	for unit in $Units.get_children():
		_assign_unit_to_cell(unit)
		
		var _error = unit.connect("picked_up", self, "_on_Unit_picked_up")
		_error = unit.connect("released", self, "_on_Unit_released")
		_error = unit.connect("snapped_to_grid", self, "_on_Unit_snapped_to_grid")
		
		unit.faction = Unit.PLAYER_FACTION


func _assign_enemies_to_cells() -> void:
	for enemy in $Enemies.get_children():
		_assign_unit_to_cell(enemy)
		
		enemy.connect("action_done", self, "_on_Enemy_action_done")
		enemy.connect("started_moving", self, "_on_Enemy_started_moving")
		
		enemy.faction = Unit.ENEMY_FACTION


func _assign_unit_to_cell(unit: Unit) -> void:
	var cell_coordinates: Vector2 = grid.get_cell_coordinates(unit.position)
	
	unit.position = grid.cell_coordinates_to_cell_origin(cell_coordinates)
	
	grid.get_cell_from_coordinates(cell_coordinates).unit = unit


func _start_player_turn() -> void:
	current_turn = Turn.PLAYER
	
	for unit in $Units.get_children():
		unit.enable_selection_area()


func _start_enemy_turn() -> void:
	current_turn = Turn.ENEMY
	
	for unit in $Units.get_children():
		unit.disable_selection_area()
	
	enemy_queue.clear()
	
	# enemy turn starts right away, there's no animation
	# enqueue enemies
	# decrease turn counter
	# if counter is zero, then move
	# after AI made its move, check for attacks
	# after that, decrease the counter of the next enemy
	# when the queue is empty, start player turn
	for enemy in $Enemies.get_children():
		enemy_queue.push_back(enemy)
	
	_update_enemy()


func _update_enemy() -> void:
	if not enemy_queue.empty():
		enemy_queue.pop_front().act(self)
	else:
		_start_player_turn()


func _on_CellArea2D_area_entered(_area: Area2D, cell: CellArea2D) -> void:
	active_unit_entered_cells[cell] = cell
	
	cell.modulate = Color.red


# Bugs to fix:
# [x] Tunneling
# [x] Dropping in same tile as unit
# [-] Unit sometimes dropped but then it can't be swapped
func _on_CellArea2D_area_exited(area: Area2D, cell: CellArea2D) -> void:
	cell.modulate = Color.white
	
	var active_unit: Unit = area.get_unit()
	
	if not active_unit.is_picked_up():
		return
	
	var _is_present: bool = active_unit_entered_cells.erase(cell)
	
	var selected_cell: CellArea2D = _find_closest_cell(active_unit.position)
	
	if selected_cell != null:
		# TODO: If there's an enemy in the selected cell then don't do this assignment
		if active_unit_last_valid_cell != active_unit_current_cell:
			active_unit_last_valid_cell = active_unit_current_cell
			
			has_active_unit_exited_cell = true
		
		active_unit_current_cell = selected_cell
		
		print("Left %s and entered %s" % [active_unit_last_valid_cell.coordinates, selected_cell.coordinates])
		
		if selected_cell.coordinates.distance_to(active_unit_last_valid_cell.coordinates) > 1.9:
			active_unit_last_valid_cell.modulate = Color.red
			printerr("Warning! Jumped more than 1 tile")
		
		_swap_units(active_unit, selected_cell.unit, active_unit_current_cell, active_unit_last_valid_cell)


func _on_Unit_picked_up(unit: Unit) -> void:
	_update_active_unit(unit)
	
	if current_turn == Turn.PLAYER:
		for other_unit in $Units.get_children():
			if other_unit != unit:
				other_unit.disable_selection_area()


func _on_Enemy_started_moving(enemy: Unit) -> void:
	_update_active_unit(enemy)


func _update_active_unit(unit: Unit) -> void:
	# Store this in unit?
	active_unit_current_cell = grid.get_cell_from_position(unit.position)
	active_unit_last_valid_cell = active_unit_current_cell
	has_active_unit_exited_cell = false
	
	assert(active_unit_current_cell.unit == unit, "Unit %s is not in cell %s" % [unit.name, active_unit_current_cell.coordinates])
	
	active_unit_entered_cells.clear()


func _clear_active_cells() -> void:
	active_unit_current_cell = null
	active_unit_last_valid_cell = null
	has_active_unit_exited_cell = false
	
	active_unit_entered_cells.clear()


func _find_closest_cell(unit_position: Vector2) -> CellArea2D:
	var minimum_distance: float = 1000000.0
	var selected_cell: CellArea2D = null
	
	for entered_cell in active_unit_entered_cells.values():
		var distance_squared: float = unit_position.distance_squared_to(entered_cell.position)
		
		if distance_squared < minimum_distance: # and cell does not contain an enemy unit (just in case)
			minimum_distance = distance_squared
			selected_cell = entered_cell
	
	return selected_cell


func _swap_units(active_unit: Unit, unit_to_swap: Unit, next_active_cell: CellArea2D, last_valid_cell: CellArea2D) -> void:
	if active_unit != unit_to_swap:
		next_active_cell.unit = active_unit
		last_valid_cell.unit = unit_to_swap
	
	if unit_to_swap != null and active_unit != unit_to_swap:
		print("Swapped from %s to %s" % [next_active_cell.coordinates, last_valid_cell.coordinates])
		
		if active_unit.is_enemy(unit_to_swap.faction):
			printerr("swapped with an enemy")
		
		unit_to_swap.move_to_new_cell(last_valid_cell.position)


func _on_Unit_released(unit: Unit) -> void:
	var selected_cell: CellArea2D = _find_closest_cell(unit.position)
	
	# TODO: If ally, then swap
	# Else, pick the last valid cell
	# FIXME: May not work always
	if active_unit_last_valid_cell != selected_cell:
		has_active_unit_exited_cell = true
	
	_swap_units(unit, selected_cell.unit, selected_cell, active_unit_current_cell)
	
	unit.snap_to_grid(selected_cell.position)
	
	# TODO: add drag timer


func _on_Unit_snapped_to_grid(unit: Unit) -> void:
	if has_active_unit_exited_cell:
		_clear_active_cells()
		
		# Adds pincers to pincer queue
		pincer_queue = $Pincerer.find_pincers(grid, unit)
		
		# TODO: execute enemy pincers
		_execute_pincers()
	else:
		# Do nothing
		_start_player_turn()


func _on_Enemy_action_done(unit: Unit) -> void:
	_clear_active_cells()
	
	assert(grid.get_cell_from_position(unit.position).unit == unit)
	
	_update_enemy()


# Builds an adjacency list with all the nodes that the given unit can visit
# Enemies may block the unit from reaching certain tiles, besides the tiles they
# already occupy
func build_navigation_graph(unit_position: Vector2, faction: int) -> Dictionary:
	var start_cell: CellArea2D = grid.get_cell_from_position(unit_position)
	
	var queue := []
	
	queue.push_back(start_cell)
	
	# {CellArea2D, bool}
	var discovered_dict := {}
	
	# {CellArea2D, [CellArea2D] (array of cells connected to this cell)}
	# Graph as adjacency list
	var navigation_graph := {}
	
	while not queue.empty():
		var node: CellArea2D = queue.pop_front()
		
		# Initialize adjacency list for the given node
		navigation_graph[node] = []
		
		# Flag as discovered
		discovered_dict[node] = true
		
		for neighbor in node.neighbors:
			if not discovered_dict.has(neighbor):
				if neighbor.unit == null or neighbor.unit.is_ally(faction):
					navigation_graph[node].push_back(neighbor)
					
					queue.push_back(neighbor)
	
	return navigation_graph


func find_path(navigation_graph: Dictionary, unit_position: Vector2, target_cell: CellArea2D) -> Array:
	# TODO: when planning for chaining, some tiles have to be avoided
	# and the path has to be split
	var start_cell: CellArea2D = grid.get_cell_from_position(unit_position)
	
	# build A Star graph?
	
	# {CellArea2D, bool}
	var discovered_dict := {}
	
	# {CellArea2D, CellArea2D}
	var parent_dict := {}
	
	var queue := []
	queue.push_back(start_cell)
	
	parent_dict[start_cell] = null
	# Array of target cells
	# and array/dict of excluded cells?
	
	# Breadth-first search (again)
	while not queue.empty():
		var node: CellArea2D = queue.pop_front()
		
		# Flag as discovered
		discovered_dict[node] = true
		
		for neighbor in navigation_graph[node]:
			if not discovered_dict.has(neighbor):
				queue.push_back(neighbor)
				
				parent_dict[neighbor] = node
	
	# Array of CellArea2D
	var path := []
	
	if parent_dict.has(target_cell):
		var node_parent = parent_dict[target_cell]
		
		while node_parent != null:
			path.push_front(node_parent.position)
			node_parent = parent_dict[node_parent]
	
	return path


func _execute_pincers() -> void:
	var pincer: Pincerer.Pincer = pincer_queue.pop_front()
	
	if pincer != null:
		# play pincer animation
		
		var attack_queue: Array = _queue_attacks(pincer)
		
		$Attacker.start_attacks(attack_queue)
		
		# TODO: Check if any targeted unit has died
	else:
		print("All pincers done!")
		
		if current_turn == Turn.PLAYER:
			_start_enemy_turn()
		else:
			_start_player_turn()


func _queue_attacks(pincer: Pincerer.Pincer) -> Array:
	var attack_queue := []
	
	for pincering_unit in pincer.pincering_units:
		_queue_attack(attack_queue, pincer.pincered_units, pincering_unit)
	
	for unit in pincer.chain_families.keys():
		_queue_chain_attacks(attack_queue, pincer.chain_families[unit], pincer.pincered_units, unit)
	
	return attack_queue


func _queue_attack(queue: Array, targeted_units: Array, attacking_unit: Unit, pincering_unit: Unit = null) -> void:
	var attack: Attack = Attack.new()
	
	attack.targeted_units = targeted_units
	attack.attacking_unit = attacking_unit
	
	if pincering_unit == null:
		attack.pincering_unit = attacking_unit
	else:
		attack.pincering_unit = pincering_unit
	
	queue.push_back(attack)


func _queue_chain_attacks(queue: Array, chains: Array, targeted_units: Array, pincering_unit: Unit) -> void:
	for chain in chains:
		for unit in chain:
			_queue_attack(queue, targeted_units, unit, pincering_unit)


## Grid utils

func _on_Attacker_attacks_done() -> void:
	_execute_pincers()
