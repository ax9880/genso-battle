extends Node2D

class_name Board

enum Turn {
	NONE, PLAYER, ENEMY
}

export(float) var time_between_enemy_appearance_seconds: float = 0.5
export(float) var time_before_player_units_appearance_seconds: float = 0.5

# Set to true to use debug units instead of the player's squad
export(bool) var can_use_debug_units: bool = false

export(PackedScene) var trail_2d_packed_scene: PackedScene

onready var grid := $Grid
onready var grid_width: int = grid.width
onready var grid_height: int = grid.height

var active_unit: Unit = null
var active_unit_current_cell: Cell = null
var active_unit_last_valid_cell: Cell = null
var active_trail: Node2D = null

# Dictionary<Cell, bool>
var active_unit_entered_cells := {}
var has_active_unit_exited_cell: bool = false

var enemy_queue := []

# Array<Pincer>
var pincer_queue := []

var possible_chained_units := []

var current_turn: int = Turn.NONE

var player_units_node: Node2D
var enemy_units_node: Node2D

var enemy_phase_count: int = 0
var current_enemy_phase: int = 0
var enemy_phases_queue: Array

var save_data: SaveData

signal drag_timer_started(timer)
signal drag_timer_stopped
signal drag_timer_reset

# Emitted when the player's turn starts.
signal player_turn_started

# Emitted when all enemies are defeated.
signal victory

# Emitted when the player has less than 2 units on the board.
signal defeat

signal enemy_phase_started(current_enemy_phase, enemy_phase_count)
signal enemies_appeared


func _ready() -> void:
	save_data = GameData.save_data
	
	$PincerExecutor.pusher = $Pusher
	
	if can_use_debug_units:
		player_units_node = $DebugUnits
		
		$Units.queue_free()
	else:
		player_units_node = $Units
		
		$DebugUnits.queue_free()
	
	_load_player_units()
	
	_connect_cell_signals()
	
	_assign_traps_to_cells()
	_load_enemy_phases()
	_load_next_enemy_phase()
	_assign_units_to_cells()
	
	_disable_player_units()
	
	_make_enemies_appear(enemy_units_node.get_children())
	
	player_units_node.hide()


func _load_player_units() -> void:
	var discarded_units := []
	
	for i in range(player_units_node.get_child_count()):
		# Load the first X active units
		if i < save_data.active_units.size():
			var index: int = save_data.active_units[i]
		
			var job: Job = save_data.jobs[index]
			
			player_units_node.get_child(i).set_job(job)
		else:
			# If there are more units than active units then we free the rest
			var discarded_unit: Unit = player_units_node.get_child(i)
			
			discarded_units.append(discarded_unit)
	
	for unit in discarded_units:
		player_units_node.remove_child(unit)
		unit.queue_free()


# Connect body enter and exit signals.
func _connect_cell_signals() -> void:
	for row in grid.grid:
		for cell in row:
			var _error = cell.connect("area_entered", self, "_on_Cell_area_entered", [cell])
			_error = cell.connect("area_exited", self, "_on_Cell_area_exited", [cell])


func _load_enemy_phases() -> void:
	enemy_phases_queue = $EnemyPhases.get_children()
	
	for enemy_phase in enemy_phases_queue:
		if not enemy_phase.get_children().empty():
			enemy_phase_count += 1
		
		$EnemyPhases.remove_child(enemy_phase)


func _load_next_enemy_phase() -> void:
	enemy_units_node = enemy_phases_queue.pop_front()
	
	if enemy_units_node == null or current_enemy_phase == enemy_phase_count:
		emit_signal("victory")
	else:
		$EnemyPhases.add_child(enemy_units_node)
		enemy_units_node.show()
		
		_assign_enemies_to_cells()
		
		current_enemy_phase += 1
		
		emit_signal("enemy_phase_started", current_enemy_phase, enemy_phase_count)


func _assign_traps_to_cells() -> void:
	for trap in $Traps.get_children():
		var cell_coordinates: Vector2 = grid.get_cell_coordinates(trap.position)
		
		trap.position = grid.cell_coordinates_to_cell_origin(cell_coordinates)
		
		grid.get_cell_from_coordinates(cell_coordinates).trap = trap


func _assign_enemies_to_cells() -> void:
	for enemy in enemy_units_node.get_children():
		_assign_unit_to_cell(enemy)
		
		enemy.connect("action_done", self, "_on_Enemy_action_done")
		enemy.connect("started_moving", self, "_on_Unit_picked_up")
		enemy.connect("use_skill", self, "_on_Enemy_use_skill")
		enemy.connect("released", self, "_on_Unit_released")
		
		if enemy.is_controlled_by_player:
			enemy.connect("picked_up", self, "_on_Unit_picked_up")
		
		enemy.faction = Unit.ENEMY_FACTION


func _assign_units_to_cells() -> void:
	for unit in player_units_node.get_children():
		_assign_unit_to_cell(unit)
		
		var _error = unit.connect("picked_up", self, "_on_Unit_picked_up")
		_error = unit.connect("released", self, "_on_Unit_released")
		_error = unit.connect("snapped_to_grid", self, "_on_Unit_snapped_to_grid")
		
		unit.faction = Unit.PLAYER_FACTION


func _assign_unit_to_cell(unit: Unit) -> void:
	var cell_coordinates: Vector2 = grid.get_cell_coordinates(unit.position)
	
	unit.position = grid.cell_coordinates_to_cell_origin(cell_coordinates)
	
	var cell: Cell = grid.get_cell_from_coordinates(cell_coordinates)
	
	if cell.unit != null:
		$Pusher.push_unit(cell, cell)
	
	assert(cell.unit == null)
	
	if unit.is2x2():
		var area_cells: Array = cell.get_cells_in_area()
		
		for area_cell in area_cells:
			if area_cell.unit != null:
				$Pusher.push_unit(area_cell, area_cell)
			
			assert(area_cell.unit == null)
			
			area_cell.unit = unit
	else:
		cell.unit = unit


func _make_enemies_appear(units: Array) -> void:
	for unit in units:
		unit.hide()
	
	for unit in units:
		unit.appear()
		
		yield(get_tree().create_timer(time_between_enemy_appearance_seconds), "timeout")
	
	yield(get_tree().create_timer(time_before_player_units_appearance_seconds), "timeout")
	
	for unit in units:
		unit.hide_name()
	
	emit_signal("enemies_appeared")
	
	_make_player_units_appear()


func _make_player_units_appear() -> void:
	if player_units_node.visible:
		return
	else:
		player_units_node.show()
		
		player_units_node.modulate = Color.transparent
		
		$Tween.interpolate_property(player_units_node, "modulate",
			player_units_node.modulate, Color.white,
			0.5)
		
		$Tween.start()
		
		yield($Tween, "tween_all_completed")
		
		_start_player_turn()


func _start_player_turn() -> void:
	print("Starting player turn")
	
	$PincerExecutor.initialize(grid, enemy_units_node.get_children(), player_units_node.get_children())
	pincer_queue = []
	
	if player_units_node.get_children().size() < SaveData.MIN_SQUAD_SIZE or has_less_than_min_squad_size_alive(player_units_node.get_children()):
		print("Defeat!")
		
		emit_signal("defeat")
	elif is_all_units_dead(enemy_units_node.get_children()):
		_load_next_enemy_phase()
		
		if enemy_units_node != null:
			_make_enemies_appear(enemy_units_node.get_children())
			
			current_turn = Turn.PLAYER
			
			emit_signal("drag_timer_reset")
			emit_signal("player_turn_started")
		
			for unit in player_units_node.get_children():
				unit.enable_selection_area()
	else:
		current_turn = Turn.PLAYER
		
		for enemy in enemy_units_node.get_children():
			enemy.reset_turn_counter()
		
		emit_signal("drag_timer_reset")
		emit_signal("player_turn_started")
		
		for unit in player_units_node.get_children():
			unit.enable_selection_area()


func has_less_than_min_squad_size_alive(units: Array) -> bool:
	var alive_counter := 0
	
	for unit in units:
		if unit.is_alive():
			alive_counter += 1
	
	return alive_counter < SaveData.MIN_SQUAD_SIZE


func is_all_units_dead(units: Array) -> bool:
	var is_all_dead := true
	
	for unit in units:
		is_all_dead = is_all_dead and unit.is_dead()
	
	return is_all_dead


func update_drag_mode(drag_mode: int) -> void:
	for unit in player_units_node.get_children():
		unit.set_drag_mode(drag_mode)


func _disable_player_units() -> void:
	for unit in player_units_node.get_children():
		unit.disable_selection_area()


func _start_enemy_turn() -> void:
	print("Starting enemy turn")
	
	current_turn = Turn.ENEMY
	
	_disable_player_units()
	
	enemy_queue.clear()
	
	if enemy_units_node.get_children().empty():
		emit_signal("victory")
	else:
		# Initialize these parameters. Allies and enemies are used when
		# checking for dead units. The grid is used when checking for
		# affected cells when using a skill
		
		# TODO: Pass these parameters to the functions that need them
		$PincerExecutor.initialize(grid, enemy_units_node.get_children(), player_units_node.get_children())
		pincer_queue = []
		
		# enemy turn starts right away, there's no animation
		# enqueue enemies
		# decrease turn counter
		# if counter is zero, then move
		# after AI made its move, check for attacks
		# after that, decrease the counter of the next enemy
		# when the queue is empty, start player turn
		for enemy in enemy_units_node.get_children():
			enemy_queue.push_back(enemy)
	
	_update_enemy()


func _update_enemy() -> void:
	_clear_active_cells()
	
	if not enemy_queue.empty():
		var enemy: Unit = enemy_queue.pop_front()
		
		enemy.act(grid, enemy_units_node.get_children(), player_units_node.get_children())
	else:
		_start_player_turn()


func _on_Cell_area_entered(_area: Area2D, cell: Cell) -> void:
	if active_unit.is2x2():
		_update_2x2_unit_cells(active_unit, cell)
	else:
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
		
		if active_unit.is2x2():
			_update_2x2_unit_cells(active_unit, selected_cell)
		else:
			_swap_units(active_unit, selected_cell.unit, active_unit_current_cell, active_unit_last_valid_cell)
			
			_highlight_possible_chains(active_unit)
			
			$ChainPreviewer.update_preview(active_unit, selected_cell)
			
			var _is_present: bool = active_unit_entered_cells.erase(cell)
		
		_activate_trap(selected_cell, active_unit)
		
		_update_trail(selected_cell)


func _update_2x2_unit_cells(unit: Unit, cell: Cell) -> void:
	assert(active_unit_entered_cells.values().size() == 4)
	assert(unit.is2x2())
	
	for entered_cell in active_unit_entered_cells.values():
		assert(entered_cell.unit == unit)
		
		entered_cell.unit = null
		
		entered_cell.modulate = Color.white
	
	_push_cells_in_area(unit, cell)
	
	active_unit_entered_cells.clear()
	
	for area_cell in cell.get_cells_in_area():
		active_unit_entered_cells[area_cell] = area_cell
		
		area_cell.modulate = Color.red
	
	assert(cell in active_unit_entered_cells)


func _push_cells_in_area(unit: Unit, cell: Cell) -> void:
	for area_cell in cell.get_cells_in_area():
		area_cell.modulate = Color.red
		
		if area_cell.unit != null and area_cell.unit != unit:
			$Pusher.push_unit(cell, area_cell)
			
		assert(area_cell.unit == null or area_cell.unit == unit)
		
		area_cell.unit = unit


func _clean_up_cells_in_area(unit: Unit, cell: Cell) -> void:
	assert(unit.is2x2())
	
	for area_cell in cell.get_cells_in_area():
		if cell.unit == unit:
			area_cell.modulate = Color.white
			
			cell.unit = null


func _update_active_unit(unit: Unit) -> void:
	active_unit = unit
	
	active_unit_current_cell = grid.get_cell_from_position(unit.position)
	
	active_unit_last_valid_cell = null
	has_active_unit_exited_cell = false
	
	assert(active_unit_current_cell.unit == unit, "Unit %s is not in cell %s" % [unit.name, active_unit_current_cell.coordinates])
	
	active_unit_entered_cells.clear()
	
	if unit.is2x2():
		_push_cells_in_area(unit, active_unit_current_cell)
		
		for cell in active_unit_current_cell.get_cells_in_area():
			active_unit_entered_cells[cell] = cell
	
	$ChainPreviewer.update_preview(unit, active_unit_current_cell)


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


func _activate_trap(cell: Cell, active_unit: Unit) -> void:
	if cell.trap != null:
		cell.trap.activate(active_unit)
		
		if active_unit.is_dead():
			active_unit.release()


func _execute_next_pincer() -> void:
	var pincer: Pincerer.Pincer = pincer_queue.pop_front()
	
	while(pincer != null and not pincer.is_valid()):
		pincer = pincer_queue.pop_front()
	
	if pincer != null:
		# TODO: Play pincer animation
		
		var _error = $PincerExecutor.connect("skill_activation_phase_finished", self, "_on_PincerExecutor_skill_activation_phase_finished", [pincer], CONNECT_ONESHOT)
		
		$PincerExecutor.start_skill_activation_phase(pincer, grid, player_units_node.get_children(), enemy_units_node.get_children())
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
	
	if $Attacker.connect("attack_phase_finished", self, "_on_Attacker_attack_phase_finished", [pincer], CONNECT_ONESHOT) != OK:
		push_warning("Signal is already connected")
	
	$Attacker.start(attack_queue)


func _start_attack_skill_phase(pincer: Pincerer.Pincer) -> void:
	var _error = $PincerExecutor.connect("attack_skill_phase_finished", self, "_on_PincerExecutor_attack_skill_phase_finished", [pincer], CONNECT_ONESHOT)
	
	$PincerExecutor.start_attack_skill_phase()


func _check_for_dead_units() -> void:
	var _error = $PincerExecutor.connect("finished_checking_for_dead_units", self, "_on_PincerExecutor_finished_checking_for_dead_units", [], CONNECT_ONESHOT)
	
	$PincerExecutor.check_dead_units()


func _start_heal_phase() -> void:
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
	var time_left_seconds = $DragTimer.time_left
	
	if not $DragTimer.is_stopped():
		$DragTimer.stop()
	
	emit_signal("drag_timer_stopped", time_left_seconds)


## Signals

func _on_Unit_picked_up(unit: Unit) -> void:
	_update_active_unit(unit)
	
	assert(active_trail == null)
	
	active_trail = trail_2d_packed_scene.instance()
	
	$Trails.add_child(active_trail)
	
	_update_trail(grid.get_cell_from_position(unit.position))
	
	unit.z_index += 1
	
	_highlight_possible_chains(unit)
	
	if current_turn == Turn.PLAYER:
		for other_unit in player_units_node.get_children():
			if other_unit != unit:
				other_unit.disable_selection_area()


func _highlight_possible_chains(unit: Unit) -> void:
	_stop_possible_chained_units_animations()
	
	var chain_families: Dictionary = {}
	
	chain_families[unit] = []
	var faction: int = unit.faction
	
	$Pincerer._find_chain(active_unit_current_cell, Cell.DIRECTION.RIGHT, chain_families, faction)
	$Pincerer._find_chain(active_unit_current_cell, Cell.DIRECTION.LEFT, chain_families, faction)
	$Pincerer._find_chain(active_unit_current_cell, Cell.DIRECTION.UP, chain_families, faction)
	$Pincerer._find_chain(active_unit_current_cell, Cell.DIRECTION.DOWN, chain_families, faction)
	
	for chains in chain_families.values():
		for chain in chains:
			for unit in chain:
				possible_chained_units.push_back(unit)
	
	for unit in possible_chained_units:
		unit.play_scale_and_and_down_animation()


func _stop_possible_chained_units_animations() -> void:
	for unit in possible_chained_units:
		unit.stop_scale_and_and_down_animation()
	
	possible_chained_units.clear()


func _update_trail(cell: Cell) -> void:
	active_trail.add(cell.position)


func _clear_active_trail() -> void:
	if active_trail != null:
		active_trail.queue_clear()
		active_trail = null


func _on_Enemy_use_skill(unit: Unit, skill: Skill) -> void:
	print("Enemy %s is going to use skill %s" %[unit.name, skill.skill_name])
	
	_stop_possible_chained_units_animations()
	
	_clear_active_trail()
	
	unit.play_skill_activation_animation([skill], 1)
	
	# Wait for it to finish
	yield(get_tree().create_timer(1.0), "timeout")
	
	var target_cells: Array = BoardUtils.find_area_of_effect_target_cells(unit.position, skill, grid)
	var filtered_cells: Array = BoardUtils.filter_cells(unit, skill, target_cells)
	
	var skill_effect: Node2D = skill.effect_scene.instance()
	
	add_child(skill_effect)
	
	var start_cell: Cell = grid.get_cell_from_position(unit.position)
	
	assert(start_cell != null)
	
	skill_effect.start(unit, skill, filtered_cells, start_cell, $Pusher)
	
	yield(skill_effect, "effect_finished")
	
	unit.z_index = 0
	
	_check_for_dead_units()


func _on_Unit_released(unit: Unit) -> void:
	_stop_drag_timer()
	
	_stop_possible_chained_units_animations()
	
	# TODO: Store original Z index ?
	unit.z_index -= 1
	
	var selected_cell: Cell = _find_closest_cell(unit.position)
	
	if active_unit_last_valid_cell == null and selected_cell != active_unit_current_cell:
		has_active_unit_exited_cell = true
	
	# TODO: If ally, then swap, else, pick the last valid cell
	# FIXME: May not work always
	if active_unit_last_valid_cell != null:
		has_active_unit_exited_cell = true
		
		print("Unit %s exited a cell" % unit.name)
	
	if unit.is2x2():
		for cell in active_unit_entered_cells:
			if cell.unit == unit:
				cell.unit = null
				cell.modulate = Color.white
		
		_push_cells_in_area(unit, selected_cell)
	
	_swap_units(unit, selected_cell.unit, selected_cell, active_unit_current_cell)
	
	unit.snap_to_grid(selected_cell.position)
	
	$ChainPreviewer.update_preview(unit, selected_cell)
	
	_update_trail(selected_cell)
	_clear_active_trail()


func _on_Unit_snapped_to_grid(unit: Unit) -> void:
	if current_turn == Turn.PLAYER:
		$ChainPreviewer.clear()
		
		$PincerExecutor.check_dead_units()
		
		yield($PincerExecutor, "finished_checking_for_dead_units")
		
		if has_active_unit_exited_cell:
			_clear_active_cells()
			
			_disable_player_units()
			
			# Adds pincers to pincer queue
			pincer_queue = $Pincerer.find_pincers(grid, unit)
			
			_execute_next_pincer()
		else:
			# Do nothing
			_start_player_turn()


func _on_Enemy_action_done(unit: Unit) -> void:
	_stop_possible_chained_units_animations()
	
	_clear_active_trail()
	
	if unit.is_alive():
		assert(grid.get_cell_from_position(unit.position).unit == unit)
	else:
		$PincerExecutor.check_dead_units()
		
		yield($PincerExecutor, "finished_checking_for_dead_units")
		
		var cell = grid.get_cell_from_position(unit.position)
	
	unit.z_index = 0
	
	if has_active_unit_exited_cell:
		_clear_active_cells()
		
		var pincers: Array = $Pincerer.find_pincers(grid, unit)
		
		pincer_queue = _filter_pincers_with_active_unit(pincers, unit)
		
		print("Found %d enemy pincers" % pincer_queue.size())
		
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
		
		_check_for_dead_units()


func _on_PincerExecutor_skill_activation_phase_finished(pincer: Pincerer.Pincer) -> void:
	_start_attack_phase(pincer)


func _on_PincerExecutor_attack_skill_phase_finished(pincer: Pincerer.Pincer) -> void:
	_check_for_dead_units()


func _on_PincerExecutor_finished_checking_for_dead_units() -> void:
	_start_heal_phase()


func _on_PincerExecutor_heal_phase_finished() -> void:
	_start_status_effect_phase()


func _on_PincerExecutor_pincer_executed() -> void:
	_execute_next_pincer()


func _on_DragTimer_timeout() -> void:
	active_unit.release()
	
	_stop_drag_timer()


func _on_Board_tree_exiting() -> void:
	# Free unused enemy phases
	for enemy_phase in enemy_phases_queue:
		enemy_phase.free()
