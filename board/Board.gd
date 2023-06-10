extends Node2D

class_name Board

enum Turn {
	NONE, PLAYER, ENEMY
}

export(float) var time_between_enemy_appearance_seconds: float = 0.5
export(float) var time_before_player_units_appearance_seconds: float = 0.5

onready var grid := $Grid
onready var grid_width: int = grid.width
onready var grid_height: int = grid.height

var active_unit: Unit = null
var active_unit_current_cell: Cell = null
var active_unit_last_valid_cell: Cell = null

# Dictionary<Cell, bool>
var active_unit_entered_cells := {}
var has_active_unit_exited_cell: bool = false

var enemy_queue := []

# Array<Pincer>
var pincer_queue := []

var current_turn: int = Turn.NONE


signal drag_timer_started(timer)
signal drag_timer_stopped
signal drag_timer_reset


func _ready() -> void:
	_connect_cell_signals()
	
	_assign_units_to_cells()
	_assign_enemies_to_cells()
	
	_disable_player_units()
	
	_make_enemies_appear($Enemies.get_children())
	
	$Units.hide()


# Connect body enter and exit signals.
func _connect_cell_signals() -> void:
	for row in grid.grid:
		for cell in row:
			var _error = cell.connect("area_entered", self, "_on_Cell_area_entered", [cell])
			_error = cell.connect("area_exited", self, "_on_Cell_area_exited", [cell])


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
		
		if enemy.is_controlled_by_player:
			enemy.connect("picked_up", self, "_on_Unit_picked_up")
			enemy.connect("released", self, "_on_Unit_released")
			#enemy.connect("snapped_to_grid", self, "_on_Unit_snapped_to_grid")
		
		enemy.faction = Unit.ENEMY_FACTION


func _assign_unit_to_cell(unit: Unit) -> void:
	var cell_coordinates: Vector2 = grid.get_cell_coordinates(unit.position)
	
	unit.position = grid.cell_coordinates_to_cell_origin(cell_coordinates)
	
	grid.get_cell_from_coordinates(cell_coordinates).unit = unit


func _make_enemies_appear(units: Array) -> void:
	for unit in units:
		unit.hide()
	
	for unit in units:
		unit.appear()
		
		yield(get_tree().create_timer(time_between_enemy_appearance_seconds), "timeout")
	
	yield(get_tree().create_timer(time_before_player_units_appearance_seconds), "timeout")
	
	_make_player_units_appear()


func _make_player_units_appear() -> void:
	if $Units.visible:
		return
	else:
		$Units.show()
		
		$Units.modulate = Color.transparent
		
		$Tween.interpolate_property($Units, "modulate",
			$Units.modulate, Color.white,
			0.5)
		
		$Tween.start()
		
		yield($Tween, "tween_all_completed")
		
		_start_player_turn()


func _start_player_turn() -> void:
	current_turn = Turn.PLAYER
	
	emit_signal("drag_timer_reset")
	
	for unit in $Units.get_children():
		unit.enable_selection_area()


func _disable_player_units() -> void:
	for unit in $Units.get_children():
		unit.disable_selection_area()


func _start_enemy_turn() -> void:
	current_turn = Turn.ENEMY
	
	_disable_player_units()
	
	enemy_queue.clear()
	
	if $Enemies.get_children().empty():
		print("Victory!")
	else:
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
	_clear_active_cells()
	
	if not enemy_queue.empty():
		var enemy: Unit = enemy_queue.pop_front()
		
		enemy.act(self)
	else:
		_start_player_turn()


func _on_Cell_area_entered(_area: Area2D, cell: Cell) -> void:
	active_unit_entered_cells[cell] = cell
	
	cell.modulate = Color.red


# Bugs to fix:
# [x] Tunneling
# [x] Dropping in same tile as unit
# [-] Unit sometimes dropped but then it can't be swapped
func _on_Cell_area_exited(area: Area2D, cell: Cell) -> void:
	cell.modulate = Color.white
	
	if not area.get_unit().is_picked_up():
		return
	
	assert(active_unit == area.get_unit(), "Unit exiting cells should be the same as the active unit")
	
	var _is_present: bool = active_unit_entered_cells.erase(cell)
	
	var selected_cell: Cell = _find_closest_cell(active_unit.position)
	
	if selected_cell != null:
		# TODO: If there's an enemy in the selected cell then don't do this assignment
		# FIXME: drag timer doesn't start when exiting first cell
		if active_unit_last_valid_cell != active_unit_current_cell:
			active_unit_last_valid_cell = active_unit_current_cell
			
			has_active_unit_exited_cell = true
			
			if current_turn == Turn.PLAYER:
				_start_drag_timer()
		
		active_unit_current_cell = selected_cell
		
		if selected_cell.coordinates.distance_to(active_unit_last_valid_cell.coordinates) > 1.5:
			active_unit_last_valid_cell.modulate = Color.red
			
			printerr("Warning! Jumped more than 1 tile")
		
		_swap_units(active_unit, selected_cell.unit, active_unit_current_cell, active_unit_last_valid_cell)


func _update_active_unit(unit: Unit) -> void:
	active_unit = unit
	
	active_unit_current_cell = grid.get_cell_from_position(unit.position)
	active_unit_last_valid_cell = null
	has_active_unit_exited_cell = false
	
	assert(active_unit_current_cell.unit == unit, "Unit %s is not in cell %s" % [unit.name, active_unit_current_cell.coordinates])
	
	active_unit_entered_cells.clear()


func _clear_active_cells() -> void:
	active_unit_current_cell = null
	active_unit_last_valid_cell = null
	has_active_unit_exited_cell = false
	
	active_unit_entered_cells.clear()


func _find_closest_cell(unit_position: Vector2) -> Cell:
	var minimum_distance: float = 1000000.0
	var selected_cell: Cell = null
	
	for entered_cell in active_unit_entered_cells.values():
		var distance_squared: float = unit_position.distance_squared_to(entered_cell.position)
		
		if distance_squared < minimum_distance: # and cell does not contain an enemy unit (just in case)
			minimum_distance = distance_squared
			selected_cell = entered_cell
	
	return selected_cell


func _swap_units(unit: Unit, unit_to_swap: Unit, next_active_cell: Cell, last_valid_cell: Cell) -> void:
	if unit != unit_to_swap:
		next_active_cell.unit = unit
		last_valid_cell.unit = unit_to_swap
	
	if unit_to_swap != null and unit != unit_to_swap:
		if unit.is_enemy(unit_to_swap.faction):
			printerr("Swapped with an enemy")
		
		unit_to_swap.move_to_new_cell(last_valid_cell.position)


# Builds an adjacency list with all the nodes that the given unit can visit
# Enemies may block the unit from reaching certain tiles, besides the tiles they
# already occupy
func build_navigation_graph(unit_position: Vector2, faction: int, movement_range: int) -> Dictionary:
	var start_cell: Cell = grid.get_cell_from_position(unit_position)
	
	var queue := []
	
	queue.push_back(start_cell)
	
	# Dictionary<Cell, bool>
	var discovered_dict := {}
	
	# Dictionary<Cell, Array<Cell> (array of cells connected to this cell)>
	# Graph as adjacency list
	var navigation_graph := {}
	
	while not queue.empty():
		var node: Cell = queue.pop_front()
		
		# Initialize adjacency list for the given node
		navigation_graph[node] = []
		
		# Flag as discovered
		discovered_dict[node] = true
		
		for neighbor in node.neighbors:
			if not discovered_dict.has(neighbor):
				if neighbor.unit == null or neighbor.unit.is_ally(faction):
					if get_distance_to_cell(start_cell, neighbor) <= movement_range:
						navigation_graph[node].push_back(neighbor)
						
						queue.push_back(neighbor)
	
	return navigation_graph


func get_distance_to_cell(start_cell: Cell, end_cell: Cell) -> float:
	return abs(end_cell.coordinates.x - start_cell.coordinates.x) + abs(end_cell.coordinates.y - start_cell.coordinates.y)


func find_path(navigation_graph: Dictionary, unit_position: Vector2, target_cell: Cell) -> Array:
	# TODO: when planning for chaining, some tiles have to be avoided
	# and the path has to be split
	# Array of target cells
	# and array/dict of excluded cells?
	var start_cell: Cell = grid.get_cell_from_position(unit_position)
	
	# Dictionary<Cell, bool>
	var discovered_dict := {}
	
	# Dictionary<Cell, Cell>
	var parent_dict := {}
	
	var queue := []
	queue.push_back(start_cell)
	
	parent_dict[start_cell] = null
	
	# Breadth-first search (again)
	while not queue.empty():
		var node: Cell = queue.pop_front()
		
		# Flag as discovered
		discovered_dict[node] = true
		
		# TODO: if target node found, exit early
		
		for neighbor in navigation_graph[node]:
			if not discovered_dict.has(neighbor):
				queue.push_back(neighbor)
				
				parent_dict[neighbor] = node
	
	# Array of Cell
	var path := []
	
	if parent_dict.has(target_cell):
		var node_parent = parent_dict[target_cell]
		
		while node_parent != null:
			path.push_front(node_parent.position)
			node_parent = parent_dict[node_parent]
	
	return path


func _execute_next_pincer() -> void:
	var pincer: Pincerer.Pincer = pincer_queue.pop_front()
	
	while(pincer != null and not pincer.is_valid()):
		pincer = pincer_queue.pop_front()
	
	if pincer != null:
		# TODO: Play pincer animation
		
		var _error = $PincerExecutor.connect("skill_activation_phase_finished", self, "_on_PincerExecutor_skill_activation_phase_finished", [pincer], CONNECT_ONESHOT)
		
		# TODO: Change allies and enemies when it's the enemy's turn
		$PincerExecutor.start_skill_activation_phase(pincer, grid, $Units.get_children(), $Enemies.get_children())
	else:
		print("All pincers done!")
		
		if current_turn == Turn.PLAYER:
			_start_enemy_turn()
		else:
			_start_player_turn()


func _execute_next_enemy_pincer() -> void:
	var pincer: Pincerer.Pincer = pincer_queue.pop_front()
	
	while(pincer != null and not pincer.is_valid()):
		pincer = pincer_queue.pop_front()
	
	if pincer != null:
		# TODO: Play pincer animation
		print("Start enemy pincers")
		
		_start_attack_phase(pincer)
	else:
		print("All enemy pincers done!")
		
		_update_enemy()


func _start_attack_phase(pincer: Pincerer.Pincer) -> void:
	var attack_queue: Array = _queue_attacks(pincer)
	
	var _error = $Attacker.connect("attack_phase_finished", self, "_on_Attacker_attack_phase_finished", [pincer], CONNECT_ONESHOT)
	
	$Attacker.start(attack_queue)


func _start_attack_skill_phase(pincer: Pincerer.Pincer) -> void:
	var _error = $PincerExecutor.connect("attack_skill_phase_finished", self, "_on_PincerExecutor_attack_skill_phase_finished", [pincer], CONNECT_ONESHOT)
	
	$PincerExecutor.start_attack_skill_phase()


func _check_for_dead_units(pincer: Pincerer.Pincer) -> void:
	var _error = $PincerExecutor.connect("finished_checking_for_dead_units", self, "_on_PincerExecutor_finished_checking_for_dead_units", [pincer], CONNECT_ONESHOT)
	
	$PincerExecutor.check_dead_units()


func _start_heal_phase(_pincer: Pincerer.Pincer) -> void:
	if current_turn == Turn.PLAYER:
		var _error = $PincerExecutor.connect("heal_phase_finished", self, "_on_PincerExecutor_heal_phase_finished", [], CONNECT_ONESHOT)
		
		$PincerExecutor.start_heal_phase()
	else:
		_execute_next_enemy_pincer()


func _start_status_effect_phase() -> void:
	$PincerExecutor.start_status_effect_phase()


func _queue_attacks(pincer: Pincerer.Pincer) -> Array:
	var attack_queue := []
	
	# Pincering units first
	for pincering_unit in pincer.pincering_units:
		_queue_attack(attack_queue, pincer.pincered_units, pincering_unit)
	
	# Chained units next
	for pincering_unit in pincer.pincering_units:
		_queue_chain_attacks(attack_queue, pincer.chain_families[pincering_unit], pincer.pincered_units, pincering_unit)
	
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


func _start_drag_timer() -> void:
	if $DragTimer.is_stopped():
		$DragTimer.start()
		
		emit_signal("drag_timer_started", $DragTimer)


func _stop_drag_timer() -> void:
	if not $DragTimer.is_stopped():
		$DragTimer.stop()
	
	emit_signal("drag_timer_stopped")


## Signals

func _on_Unit_picked_up(unit: Unit) -> void:
	_update_active_unit(unit)
	
	if current_turn == Turn.PLAYER:
		for other_unit in $Units.get_children():
			if other_unit != unit:
				other_unit.disable_selection_area()


func _on_Enemy_started_moving(enemy: Unit) -> void:
	_update_active_unit(enemy)


func _on_Unit_released(unit: Unit) -> void:
	_stop_drag_timer()
	
	var selected_cell: Cell = _find_closest_cell(unit.position)
	
	if active_unit_last_valid_cell == null and selected_cell != active_unit_current_cell:
		has_active_unit_exited_cell = true
	
	# TODO: If ally, then swap, else, pick the last valid cell
	# FIXME: May not work always
	if active_unit_last_valid_cell != null:
		has_active_unit_exited_cell = true
		
		print("Unit %s exited a cell" % unit.name)
	
	_swap_units(unit, selected_cell.unit, selected_cell, active_unit_current_cell)
	
	unit.snap_to_grid(selected_cell.position)


func _on_Unit_snapped_to_grid(unit: Unit) -> void:
	if current_turn == Turn.PLAYER:
		if has_active_unit_exited_cell:
			_clear_active_cells()
			
			_disable_player_units()
			
			# Adds pincers to pincer queue
			pincer_queue = $Pincerer.find_pincers(grid, unit)
			
			# TODO: execute enemy pincers
			_execute_next_pincer()
		else:
			# Do nothing
			_start_player_turn()


func _on_Enemy_action_done(unit: Unit) -> void:
	if unit.is_alive():
		assert(grid.get_cell_from_position(unit.position).unit == unit)
	else:
		assert(grid.get_cell_from_position(unit.position).unit == null)
	
	if has_active_unit_exited_cell:
		var pincers: Array = $Pincerer.find_pincers(grid, unit)
		
		pincer_queue = _filter_pincers_with_active_unit(pincers, unit)
		
		_execute_next_enemy_pincer()
	else:
		_update_enemy()


func _filter_pincers_with_active_unit(pincers: Array, unit: Unit) -> Array:
	var filtered_pincers := []
	
	for pincer in pincers:
		if pincer.pincering_units.find(unit) != -1:
			filtered_pincers.push_back(pincer)
	
	return filtered_pincers


func _on_Attacker_attack_phase_finished(pincer: Pincerer.Pincer) -> void:
	if current_turn == Turn.PLAYER:
		_start_attack_skill_phase(pincer)
	else:
		print("Checking for dead units killed by enemies")
		
		$PincerExecutor.grid = grid
		$PincerExecutor.allies = $Enemies.get_children()
		$PincerExecutor.enemies = $Units.get_children()
		
		_check_for_dead_units(pincer)


func _on_PincerExecutor_skill_activation_phase_finished(pincer: Pincerer.Pincer) -> void:
	_start_attack_phase(pincer)


func _on_PincerExecutor_attack_skill_phase_finished(pincer: Pincerer.Pincer) -> void:
	_check_for_dead_units(pincer)


func _on_PincerExecutor_finished_checking_for_dead_units(pincer: Pincerer.Pincer) -> void:
	_start_heal_phase(pincer)


func _on_PincerExecutor_heal_phase_finished() -> void:
	_start_status_effect_phase()


func _on_PincerExecutor_pincer_executed() -> void:
	_execute_next_pincer()


func _on_DragTimer_timeout() -> void:
	active_unit.release()
	
	_stop_drag_timer()
