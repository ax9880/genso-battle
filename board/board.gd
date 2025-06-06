class_name Board
extends Node2D


enum Turn {
	NONE, PLAYER, ENEMY
}


signal drag_timer_started(timer)
signal drag_timer_stopped
signal drag_timer_reset

# Emitted when the player's turn starts.
signal player_turn_started

# Emitted when all enemies are defeated.
signal victory

# Emitted when the player has less than 2 units on the board.
signal defeat

signal enemy_phase_started(_current_enemy_phase, _enemy_phase_count)
signal enemies_appeared

signal unit_selected_for_view(job)

# Set to true to use debug units instead of the player's squad
export(bool) var can_use_debug_units: bool = false

# Maximum amount of player units loaded into the field
export(int, 2, 6) var player_units_count: int = 6

# Fixed player units level
export(int, -1, 100) var fixed_player_units_level: int = -1

var _active_unit: Unit = null
var _active_unit_current_cell: Cell = null
var _active_unit_last_valid_cell: Cell = null
var _active_trail: Node2D = null

# Dictionary<Cell, Cell>
var _active_unit_entered_cells := {}
var _has_active_unit_exited_cell: bool = false
var _has_active_unit_used_skill: bool = false

var _enemy_queue := []

# Array<Pincer>
var _pincer_queue := []

var _completed_enemy_pincers := []

var _possible_chained_units := []

var _current_turn: int = Turn.NONE

var _player_units_node: Node2D
var _enemy_units_node: Node2D

var _enemy_phase_count: int = 0
var _current_enemy_phase: int = 0
var _enemy_phases_queue: Array

var _save_data: SaveData

var _is_battle_finished: bool = false

onready var _grid := $Grid


func _ready() -> void:
	randomize()
	
	_save_data = GameData.save_data
	
	$PincerExecutor.pusher = $Pusher
	
	if can_use_debug_units:
		_player_units_node = $DebugUnits
		
		$PlayerUnits.queue_free()
	else:
		_player_units_node = $PlayerUnits
		
		$DebugUnits.queue_free()
	
	_load_player_units()
	
	_connect_cell_signals()
	
	_assign_traps_to_cells()
	_load_enemy_phases()
	_load_next_enemy_phase()
	_assign_units_to_cells()
	
	_disable_unit_selection()
	
	_player_units_node.hide()
	
	_make_enemies_appear(_enemy_units_node.get_children())


func _process(_delta: float) -> void:
	if OS.is_debug_build():
		if Input.is_action_just_pressed("ui_home"):
			emit_signal("victory")


# Units node
func _load_player_units() -> void:
	var discarded_units := []
	
	for i in _player_units_node.get_child_count():
		# Load the first X active units
		if i < player_units_count and i < _save_data.active_units.size():
			var index: int = _save_data.active_units[i]
			
			var job: Job = _save_data.jobs[index]
			
			if fixed_player_units_level > 0:
				job.level = fixed_player_units_level
			
			var unit: Unit = _player_units_node.get_child(i)
			
			unit.set_job(job)
		else:
			# If there are more units than active units then we free the rest
			var discarded_unit: Unit = _player_units_node.get_child(i)
			
			discarded_units.append(discarded_unit)
	
	for unit in discarded_units:
		_player_units_node.remove_child(unit)
		unit.queue_free()


# Connect body enter and exit signals.
func _connect_cell_signals() -> void:
	for row in _grid.grid:
		for cell in row:
			var _error = cell.connect("area_entered", self, "_on_Cell_area_entered", [cell])
			_error = cell.connect("area_exited", self, "_on_Cell_area_exited", [cell])


# EnemyPhases
func _load_enemy_phases() -> void:
	_enemy_phases_queue = $EnemyPhases.get_children()
	
	for enemy_phase in _enemy_phases_queue:
		if not enemy_phase.get_children().empty():
			_enemy_phase_count += 1
		
		$EnemyPhases.remove_child(enemy_phase)


# EnemyPhases
func _load_next_enemy_phase() -> void:
	if _current_enemy_phase == _enemy_phase_count:
		emit_signal("victory")
		
		_current_enemy_phase += 1
	else:
		_enemy_units_node = _enemy_phases_queue[_current_enemy_phase]
	
		$EnemyPhases.add_child(_enemy_units_node)
		_enemy_units_node.show()
		
		_assign_enemies_to_cells()
		
		_current_enemy_phase += 1
		
		emit_signal("enemy_phase_started", _current_enemy_phase, _enemy_phase_count)


# Traps?
func _assign_traps_to_cells() -> void:
	for trap in $Traps.get_children():
		var cell_coordinates: Vector2 = _grid.get_cell_coordinates(trap.position)
		
		trap.position = _grid.cell_coordinates_to_cell_origin(cell_coordinates)
		
		_grid.get_cell_from_coordinates(cell_coordinates).trap = trap


# Grid? Or here?
func _assign_enemies_to_cells() -> void:
	for enemy in _enemy_units_node.get_children():
		_assign_unit_to_cell(enemy)
		
		enemy.connect("action_done", self, "_on_Enemy_action_done")
		enemy.connect("started_moving", self, "_on_Unit_picked_up")
		enemy.connect("use_skill", self, "_on_Enemy_use_skill")
		enemy.connect("use_delayed_skill", self, "_on_Enemy_use_delayed_skill")
		enemy.connect("released", self, "_on_Unit_released")
		enemy.connect("selected_for_view", self, "_on_Unit_selected_for_view")
		enemy.connect("dead", self, "_on_Enemy_dead")
		
		if enemy.is_controlled_by_player:
			enemy.connect("picked_up", self, "_on_Unit_picked_up")
		
		enemy.faction = Unit.ENEMY_FACTION


func _assign_units_to_cells() -> void:
	for unit in _player_units_node.get_children():
		_assign_unit_to_cell(unit)
		
		var _error = unit.connect("picked_up", self, "_on_Unit_picked_up")
		_error = unit.connect("released", self, "_on_Unit_released")
		_error = unit.connect("snapped_to_grid", self, "_on_Unit_snapped_to_grid")
		_error = unit.connect("selected_for_view", self, "_on_Unit_selected_for_view")
		
		unit.faction = Unit.PLAYER_FACTION


func _assign_unit_to_cell(unit: Unit) -> void:
	var cell_coordinates: Vector2 = _grid.get_cell_coordinates(unit.position)
	
	unit.position = _grid.cell_coordinates_to_cell_origin(cell_coordinates)
	
	var cell: Cell = _grid.get_cell_from_coordinates(cell_coordinates)
	
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


# EnemyPhases
func _make_enemies_appear(units: Array) -> void:
	for unit in units:
		unit.hide()
	
	# Delay before showing units
	$PlayerAppearanceTimer.start()
	
	yield($PlayerAppearanceTimer, "timeout")
	
	for unit in units:
		$EnemyAppearanceTimer.start()
		
		unit.appear()
		
		yield($EnemyAppearanceTimer, "timeout")
	
	$PlayerAppearanceTimer.start()
	
	yield($PlayerAppearanceTimer, "timeout")
	
	for unit in units:
		unit.hide_name()
	
	emit_signal("enemies_appeared")
	
	_make_player_units_appear()


func _make_player_units_appear() -> void:
	if _player_units_node.visible:
		return
	else:
		_player_units_node.show()
		
		_player_units_node.modulate = Color.transparent
		
		$Tween.interpolate_property(_player_units_node, "modulate",
			_player_units_node.modulate, Color.white,
			0.5)
		
		$Tween.start()
		
		yield($Tween, "tween_all_completed")
		
		# TODO: Apply equip skills
		
		_start_turn_zero_enemy_turn()


func _start_turn_zero_enemy_turn() -> void:
	print("Starting turn 0 enemy turn")
	
	_current_turn = Turn.ENEMY
	
	_disable_unit_selection()
	
	_initialize_enemy_pincer_executor()
	
	_enemy_queue.clear()
	
	for enemy in _enemy_units_node.get_children():
		if enemy.turn_counter == 0:
			enemy.pick_next_action()
			
			_enemy_queue.push_back(enemy)
	
	_update_enemy()


func _start_player_turn(var has_same_cell: bool = false) -> void:
	print("Starting player turn")
	
	$PincerExecutor.initialize(_grid, _enemy_units_node.get_children(), _player_units_node.get_children())
	_pincer_queue.clear()
	
	_current_turn = Turn.PLAYER
	
	if _player_units_node.get_children().size() < SaveData.MIN_SQUAD_SIZE or _has_less_than_min_squad_size_alive(_player_units_node.get_children()):
		print("Defeat!")
		
		emit_signal("defeat")
	elif _is_all_units_dead(_enemy_units_node.get_children()):
		_load_next_enemy_phase()
		
		if _current_enemy_phase <= _enemy_phase_count:
			_make_enemies_appear(_enemy_units_node.get_children())
			
			# TODO: Yield to wait until enemies appear
		
		_enable_unit_selection()
		
		emit_signal("drag_timer_reset")
		
		if not has_same_cell:
			emit_signal("player_turn_started")
	elif _can_any_unit_act(_player_units_node.get_children()):
		for enemy in _enemy_units_node.get_children():
			enemy.reset_turn_counter()
		
		_enable_unit_selection()
		
		emit_signal("drag_timer_reset")
		
		if not has_same_cell:
			emit_signal("player_turn_started")
	else:
		print("Skipped player turn")
		
		for enemy in _enemy_units_node.get_children():
			enemy.reset_turn_counter()
		
		emit_signal("drag_timer_reset")
		emit_signal("player_turn_started")
		
		$PlayerSkipTurnTimer.start()
		
		yield($PlayerSkipTurnTimer, "timeout")
		
		_start_enemy_turn()


func _initialize_enemy_pincer_executor() -> void:
	# Initialize these parameters. Allies and enemies are used when
	# checking for dead units. The _grid is used when checking for
	# affected cells when using a skill
	$PincerExecutor.initialize(_grid, _enemy_units_node.get_children(), _player_units_node.get_children())
	
	_pincer_queue.clear()
	_completed_enemy_pincers.clear()


func _has_less_than_min_squad_size_alive(units: Array) -> bool:
	var alive_counter := 0
	
	for unit in units:
		if unit.is_alive():
			alive_counter += 1
	
	return alive_counter < SaveData.MIN_SQUAD_SIZE


func _is_all_units_dead(units: Array) -> bool:
	for unit in units:
		if unit.is_alive():
			return false
	
	return true


func _can_any_unit_act(units: Array) -> bool:
	for unit in units:
		if unit.can_act():
			return true
	
	return false


# Use global signal?
func update_drag_mode(drag_mode: int) -> void:
	for unit in _player_units_node.get_children():
		unit.set_drag_mode(drag_mode)
	
	for unit in _enemy_units_node.get_children():
		unit.set_drag_mode(drag_mode)


func on_give_up() -> void:
	if _active_unit != null and _active_unit.is_player():
		_is_battle_finished = true
		
		_active_unit.release()


func _enable_unit_selection() -> void:
	_enable_units(_player_units_node.get_children())
	_enable_units(_enemy_units_node.get_children())


func _disable_unit_selection() -> void:
	_disable_units(_player_units_node.get_children())
	_disable_units(_enemy_units_node.get_children())


func _enable_units(units: Array) -> void:
	for unit in units:
		unit.enable_selection_area()


func _disable_units(units: Array) -> void:
	for unit in units:
		unit.disable_selection_area()


func _start_enemy_turn() -> void:
	print("Starting enemy turn")
	
	_current_turn = Turn.ENEMY
	
	_disable_unit_selection()
	
	_enemy_queue.clear()
	
	if _enemy_units_node.get_children().empty():
		emit_signal("victory")
	else:
		_initialize_enemy_pincer_executor()
		
		# enemy turn starts right away, there's no animation
		# enqueue enemies
		# decrease turn counter
		# if counter is zero, then move
		# after AI made its move, check for attacks
		# after that, decrease the counter of the next enemy
		# when the queue is empty, start player turn
		for enemy in _enemy_units_node.get_children():
			enemy.pick_next_action()
			
			_enemy_queue.push_back(enemy)
	
	_update_enemy()


func _update_enemy() -> void:
	_clear_active_cells()
	
	if not _enemy_queue.empty():
		var enemy: Unit = _enemy_queue.pop_front()
		
		print("Active enemy is %s" % enemy.name)
		_active_unit = enemy
		_has_active_unit_used_skill = false
		
		enemy.act(_grid, _enemy_units_node.get_children(), _player_units_node.get_children(), _enemy_queue)
	else:
		_update_status_effects()


# Move to UnitMonitor/GridMonitor/CellMonitor ?
# UnitMovementMonitor
func _on_Cell_area_entered(_area: Area2D, cell: Cell) -> void:
	assert(_active_unit != null)
	
	if cell != _active_unit_current_cell:
		_active_unit.on_enter_cell()
	
	if _active_unit.is2x2():
		var previously_entered_cells: Dictionary = _active_unit_entered_cells.duplicate()
		
		_update_2x2_unit_cells(_active_unit, cell)
		
		for cell in _active_unit_entered_cells:
			if not cell in previously_entered_cells:
				_activate_trap(cell, _active_unit)
	else:
		_active_unit_entered_cells[cell] = cell
		
		_color_cell(cell)


# Bugs to fix:
# [x] Tunneling
# [x] Dropping in same tile as unit
# [-] Unit sometimes dropped but then it can't be swapped
func _on_Cell_area_exited(area: Area2D, cell: Cell) -> void:
	cell.modulate = Color.white
	
	if not area.get_unit().is_picked_up():
		return
	
	assert(_active_unit == area.get_unit(), "Unit exiting cells should be the same as the active unit")
	
	var selected_cell: Cell = _find_closest_cell(_active_unit.position)
	
	if selected_cell != null:
		# TODO: If there's an enemy in the selected cell then don't do this assignment
		if _active_unit_last_valid_cell != _active_unit_current_cell:
			_active_unit_last_valid_cell = _active_unit_current_cell
			
			_has_active_unit_exited_cell = true
			
			if _current_turn == Turn.PLAYER:
				_start_drag_timer()
		
		_active_unit_current_cell = selected_cell
		
		if selected_cell.coordinates.distance_to(_active_unit_last_valid_cell.coordinates) > 1.5:
			_color_cell(_active_unit_last_valid_cell)
			
			printerr("Warning! Jumped more than 1 tile")
		
		if _active_unit.is2x2():
			_update_2x2_unit_cells(_active_unit, selected_cell)
		else:
			var unit_to_swap: Unit = selected_cell.unit
			
			_swap_units(_active_unit, selected_cell.unit, _active_unit_current_cell, _active_unit_last_valid_cell)
			
			if selected_cell != _active_unit_last_valid_cell:
				_activate_trap(selected_cell, _active_unit)
			
			_highlight_possible_chains(_active_unit)
			
			$ChainPreviewer.update_preview(_active_unit, selected_cell)
			
			var _is_present: bool = _active_unit_entered_cells.erase(cell)
			
			if unit_to_swap != null and unit_to_swap.is_dead():
				$PincerExecutor.update_dead_unit_on_swap(unit_to_swap, _active_unit_last_valid_cell)
		
		_update_trail(selected_cell)


func _update_2x2_unit_cells(unit: Unit, cell: Cell) -> void:
	assert(_active_unit_entered_cells.values().size() == 4)
	assert(unit.is2x2())
	
	for entered_cell in _active_unit_entered_cells.values():
		assert(entered_cell.unit == unit)
		
		entered_cell.unit = null
		
		entered_cell.modulate = Color.white
	
	_push_cells_in_area(unit, cell)
	
	_active_unit_entered_cells.clear()
	
	for area_cell in cell.get_cells_in_area():
		_active_unit_entered_cells[area_cell] = area_cell
		
		_color_cell(area_cell)
	
	assert(cell in _active_unit_entered_cells)
	assert(cell.unit == unit)


func _push_cells_in_area(unit: Unit, cell: Cell) -> void:
	for area_cell in cell.get_cells_in_area():
		_color_cell(area_cell)
		
		if area_cell.unit != null and area_cell.unit != unit:
			$Pusher.push_unit(cell, area_cell)
		
		assert(area_cell.unit == null or area_cell.unit == unit)
		
		area_cell.unit = unit


func _clean_up_cells_in_area(unit: Unit, cell: Cell) -> void:
	assert(unit.is2x2())
	
	for area_cell in cell.get_cells_in_area():
		if area_cell.unit == unit:
			area_cell.modulate = Color.white
			
			area_cell.unit = null


func _update_active_unit(unit: Unit) -> void:
	_active_unit = unit
	
	_active_unit_current_cell = _grid.get_cell_from_position(unit.position)
	
	_active_unit_last_valid_cell = null
	_has_active_unit_exited_cell = false
	
	assert(_active_unit_current_cell.unit == unit, "Unit %s is not in cell %s" % [unit.name, _active_unit_current_cell.coordinates])
	
	_active_unit_entered_cells.clear()
	
	if unit.is2x2():
		_push_cells_in_area(unit, _active_unit_current_cell)
		
		for cell in _active_unit_current_cell.get_cells_in_area():
			_active_unit_entered_cells[cell] = cell
	
	$ChainPreviewer.update_preview(unit, _active_unit_current_cell)


func _clear_active_cells() -> void:
	_active_unit_current_cell = null
	_active_unit_last_valid_cell = null
	_has_active_unit_exited_cell = false
	
	_active_unit_entered_cells.clear()


func _color_cell(cell: Cell) -> void:
	if OS.is_debug_build():
		cell.modulate = Color.red


func _find_closest_cell(unit_position: Vector2) -> Cell:
	# If empty then unit hasn't moved
	if _active_unit_entered_cells.empty():
		var cell = _grid.get_cell_from_position(unit_position)
		
		assert(cell.unit != null)
		
		return cell
	else:
		var selected_cell: Cell = null
		var minimum_distance: float = 1000000.0
		
		for entered_cell in _active_unit_entered_cells.values():
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
		
		assert(!unit_to_swap.is2x2())
		
		unit_to_swap.move_to_new_cell(last_valid_cell.position)
		
		_activate_trap(last_valid_cell, unit_to_swap)


# Move to cell?
func _activate_trap(cell: Cell, unit: Unit) -> void:
	if cell.trap != null:
		print("Trap activated! %s" % unit.name)
		
		cell.trap.activate(unit)
		
		if unit.is_dead():
			unit.release()


func _execute_pincers(unit: Unit) -> void:
	$PincerExecutor.check_dead_units()
	
	yield($PincerExecutor, "finished_checking_for_dead_units")
	
	_pincer_queue = $Pincerer.find_pincers(_grid, unit)
	
	if _current_turn == Turn.ENEMY:
		_pincer_queue = _filter_pincers_with_active_unit(_pincer_queue, unit)
		
		_completed_enemy_pincers.append_array(_pincer_queue)
	
	print("Found %d pincers" % _pincer_queue.size())
	
	while not _pincer_queue.empty() and _pincer_queue.front() != null:
		var pincer: Pincer = _pincer_queue.pop_front()
		
		$Pincerer.find_chains(_grid, pincer)
		
		if not pincer.is_valid():
			continue
		
		print("Evaluating pincer")
		
		if _current_turn == Turn.ENEMY:
			_set_turn_counter_of_pincering_units(unit, pincer)
		
		$PincerExecutor.highlight_pincer(pincer)
		
		yield($PincerExecutor, "pincer_highlighted")
		
		if _current_turn == Turn.PLAYER:
			$PincerExecutor.start_skill_activation_phase(pincer, _grid, _player_units_node.get_children(), _enemy_units_node.get_children())
			
			yield($PincerExecutor, "skill_activation_phase_finished")
		
		$PincerExecutor.start_buff_skill_phase()
		yield($PincerExecutor, "buff_skill_phase_finished")
		
		$Attacker.start(pincer)
		yield($Attacker, "attack_phase_finished")
		
		$PincerExecutor.start_attack_skill_phase()
		yield($PincerExecutor, "attack_skill_phase_finished")
		
		$PincerExecutor.check_dead_units()
		yield($PincerExecutor, "finished_checking_for_dead_units")
		
		if _current_turn == Turn.PLAYER:
			$PincerExecutor.start_heal_phase()
			
			yield($PincerExecutor, "heal_phase_finished")
		
		if _current_turn == Turn.ENEMY:
			# Removes the unit (besides the active unit) that performed the
			# pincer from the queue, so it doesn't act again in the same turn 
			_remove_pincering_units_from_enemy_queue(unit, pincer)
	
	print("All pincers done!")
	
	$PincerExecutor.clear_chain_previews()
	
	if _current_turn == Turn.PLAYER:
		_start_enemy_turn()
	else:
		_update_enemy()


func _set_turn_counter_of_pincering_units(unit: Unit, pincer: Pincer) -> void:
	for pincering_unit in pincer.pincering_units:
		if pincering_unit != unit and pincering_unit.has_pincer_action() and pincering_unit.turn_counter != 0:
			pincering_unit.turn_counter = 0


func _remove_pincering_units_from_enemy_queue(unit: Unit, pincer: Pincer) -> void:
	for pincering_unit in pincer.pincering_units:
		if pincering_unit != unit and pincering_unit.has_pincer_action():
			var index := _enemy_queue.find(pincering_unit)
			
			if index != -1:
				_enemy_queue.remove(index)


func _update_status_effects() -> void:
	# TODO: Apply trap damage to units standing inside traps
	
	# TODO: Move confused units if confusion is implemented
	
	$PincerExecutor.start_status_effect_phase()
	
	yield($PincerExecutor, "status_effect_phase_finished")
	
	$PincerExecutor.check_dead_units()
	
	yield($PincerExecutor, "finished_checking_for_dead_units")
	
	_start_player_turn()


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
	
	assert(_active_trail == null)
	
	if not unit.is2x2():
		_active_trail = $Trails.build_trail(_current_turn == Turn.PLAYER)
	
	_update_trail(_grid.get_cell_from_position(unit.position))
	
	unit.z_index += 1
	
	_highlight_possible_chains(unit)
	
	if _current_turn == Turn.PLAYER:
		for other_unit in _player_units_node.get_children():
			if other_unit != unit:
				other_unit.disable_selection_area()


func _highlight_possible_chains(unit: Unit) -> void:
	if unit.faction != Unit.PLAYER_FACTION:
		return
	
	_stop_possible_chained_units_animations()
	
	var chain_families: Dictionary = {}
	
	chain_families[unit] = []
	var faction: int = unit.faction
	
	$Pincerer._find_chain(_active_unit_current_cell, Cell.DIRECTION.RIGHT, chain_families, faction)
	$Pincerer._find_chain(_active_unit_current_cell, Cell.DIRECTION.LEFT, chain_families, faction)
	$Pincerer._find_chain(_active_unit_current_cell, Cell.DIRECTION.UP, chain_families, faction)
	$Pincerer._find_chain(_active_unit_current_cell, Cell.DIRECTION.DOWN, chain_families, faction)
	
	for chains in chain_families.values():
		for chain in chains:
			for unit in chain:
				_possible_chained_units.push_back(unit)
	
	for unit in _possible_chained_units:
		unit.play_scale_up_and_down_animation()


func _stop_possible_chained_units_animations() -> void:
	for unit in _possible_chained_units:
		unit.stop_scale_up_and_down_animation()
	
	_possible_chained_units.clear()


func _update_trail(cell: Cell) -> void:
	if _active_trail != null:
		_active_trail.add(cell.position)


func _clear_active_trail() -> void:
	if _active_trail != null:
		_active_trail.queue_clear()
		_active_trail = null


func _on_Enemy_use_skill(unit: Unit, skill: Skill, target_cells: Array) -> void:
	print("Enemy %s is going to use skill %s" %[unit.name, skill.skill_name])
	
	_has_active_unit_used_skill = true
	
	$DelayedSkillHighlighter.remove(unit, skill)
	
	_play_skill_activation_animation(unit, skill)
	
	# Wait for it to finish
	$PincerExecutor/BeforeSkillActivationPhaseFinishesTimer.start()
	
	yield($PincerExecutor/BeforeSkillActivationPhaseFinishesTimer, "timeout")
	
	$PincerExecutor/BeforeSkillActivationPhaseFinishesTimer.stop()
	
	var skill_effect: Node2D = skill.effect_scene.instance()
	add_child(skill_effect)
	
	var start_cell: Cell = _grid.get_cell_from_position(unit.position)
	
	assert(start_cell != null)
	
	target_cells = BoardUtils.filter_cells(unit, skill, target_cells)
	
	skill_effect.start(unit, skill, target_cells, start_cell, $Pusher)
	
	yield(skill_effect, "effect_finished")
	
	unit.z_index = 0
	
	$PincerExecutor.check_dead_units()
	
	yield($PincerExecutor, "finished_checking_for_dead_units")
	
	unit.on_skill_used(_grid, _player_units_node.get_children())


func _on_Enemy_use_delayed_skill(unit: Unit, skill: Skill, target_cells: Array) -> void:
	print("Enemy %s is preparing to use skill %s" %[unit.name, skill.skill_name])
	
	$DelayedSkillHighlighter.highlight(unit, skill, target_cells)
	
	_play_skill_activation_animation(unit, skill)
	
	# Wait for it to finish
	$PincerExecutor/BeforeSkillActivationPhaseFinishesTimer.start()
	
	yield($PincerExecutor/BeforeSkillActivationPhaseFinishesTimer, "timeout")
	
	$PincerExecutor/BeforeSkillActivationPhaseFinishesTimer.stop()
	
	_update_enemy()


func _play_skill_activation_animation(unit: Unit, skill: Skill) -> void:
	$ChainPreviewer.clear()
	
	_stop_possible_chained_units_animations()
	
	_clear_active_trail()
	
	unit.play_skill_activation_animation([skill], 2)


func _on_Unit_released(unit: Unit) -> void:
	print("Unit %s released" % unit.name)
	
	_stop_drag_timer()
	
	_stop_possible_chained_units_animations()
	
	# TODO: Store original Z index ?
	unit.z_index -= 1
	
	var selected_cell: Cell = _find_closest_cell(unit.position)
	
	assert(selected_cell != null)
	
	if unit.is2x2():
		var cell_below: Cell = _grid.get_cell_from_position(unit.position)
		
		if unit.position.distance_squared_to(cell_below.position) < unit.position.distance_squared_to(selected_cell.position):
			selected_cell = cell_below
	
	if _active_unit_last_valid_cell == null and selected_cell != _active_unit_current_cell:
		_has_active_unit_exited_cell = true
	
	# FIXME: May not work always
	if _active_unit_last_valid_cell != null:
		_has_active_unit_exited_cell = true
		
		print("Unit %s exited a cell" % unit.name)
	
	if _active_unit_current_cell != selected_cell:
		_activate_trap(selected_cell, unit)
	
	if unit.is2x2():
		_update_2x2_unit_cells(unit, selected_cell)
		
		for cell in _active_unit_entered_cells:
			if cell.unit == unit:
				cell.modulate = Color.white
	else:
		# If there is a unit in the selected cell swap with it
		_swap_units(unit, selected_cell.unit, selected_cell, _active_unit_current_cell)
	
	unit.snap_to_grid(selected_cell.position)
	
	$ChainPreviewer.update_preview(unit, selected_cell)
	
	assert(selected_cell.unit == unit)
	
	_update_trail(selected_cell)
	_clear_active_trail()


func _on_Unit_snapped_to_grid(unit: Unit) -> void:
	print("Unit %s snapped to _grid" % unit.name)
	
	$ChainPreviewer.clear()
	
	if _is_battle_finished:
		return
	
	if _current_turn == Turn.PLAYER:
		if unit.is_dead():
			_stop_possible_chained_units_animations()
		
		$PincerExecutor.check_dead_units()
		
		yield($PincerExecutor, "finished_checking_for_dead_units")
		
		if _has_active_unit_exited_cell:
			_clear_active_cells()
			
			_disable_unit_selection()
			
			_execute_pincers(unit)
		else:
			# Do nothing
			# Has same cell = true
			_start_player_turn(true)


func _on_Unit_selected_for_view(unit: Unit) -> void:
	emit_signal("unit_selected_for_view", unit)


func _on_Enemy_dead(unit: Unit) -> void:
	$DelayedSkillHighlighter.remove_all(unit)


func _on_Enemy_action_done(unit: Unit) -> void:
	if unit != _active_unit:
		push_warning("Unexpected unit %s action done" % unit.name)
		
		return
	
	print("Enemy %s action done" % unit.name)
	
	_stop_possible_chained_units_animations()
	
	_clear_active_trail()
	
	if unit.is_alive():
		if _grid.get_cell_from_position(unit.position).unit != unit:
			push_error("Unit in cell of active unit %s is not the active unit" % unit.name)
	
	$PincerExecutor.check_dead_units()
	
	yield($PincerExecutor, "finished_checking_for_dead_units")
	
	unit.z_index = 0
	
	if not _has_active_unit_used_skill:
		_clear_active_cells()
		
		_execute_pincers(unit)
	else:
		_update_enemy()


func _filter_pincers_with_active_unit(pincers: Array, unit: Unit) -> Array:
	var filtered_pincers := []
	
	for pincer in pincers:
		# Also check that the active unit can actually act this turn to avoid
		# pincering units when none of the enemies can act, for example when the
		# player is between two enemies and does not move
		if pincer.pincering_units.find(unit) != -1 and not _has_executed_pincer_before(pincer) and unit.turn_counter == 0:
			filtered_pincers.push_back(pincer)
	
	return filtered_pincers


func _has_executed_pincer_before(pincer: Pincer) -> bool:
	assert( pincer.pincering_units.size() == 2)
	
	var unit_1: Unit = pincer.pincering_units[0]
	var unit_2: Unit = pincer.pincering_units[1]
	
	for completed_pincer in _completed_enemy_pincers:
		if (unit_1 == completed_pincer.pincering_units[0] and unit_2 == completed_pincer.pincering_units[1]) or \
			(unit_1 == completed_pincer.pincering_units[1] and unit_2 == completed_pincer.pincering_units[0]):
			return true
	
	return false


func _on_DragTimer_timeout() -> void:
	_active_unit.release()
	
	_stop_drag_timer()


func _on_Board_tree_exiting() -> void:
	# Free unused enemy phases
	for enemy_phase in _enemy_phases_queue:
		enemy_phase.free()


func _on_StatusEffectIconAnimationTimer_timeout() -> void:
	for unit in _player_units_node.get_children():
		unit.update_status_effects_icons()
	
	for unit in _enemy_units_node.get_children():
		unit.update_status_effects_icons()
	
