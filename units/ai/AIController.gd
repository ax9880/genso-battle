extends Node


class ActionParameters extends Reference:
	var enemy: Enemy
	
	var grid: Grid
	
	# Array<Unit>
	# Enemy units
	var allies: Array
	
	# Array<Unit>
	# Player units
	var enemies: Array
	
	var action: Action
	
	# Array<Unit>
	var allies_queue: Array
	
	var navigation_graph: Dictionary
	
	
	func build_navigation_graph() -> void:
		navigation_graph = BoardUtils.build_navigation_graph(grid, enemy.position, enemy.faction, enemy.get_stats().movement_range)
	
	
	func find_path(target_cell: Cell, excluded_cells: Dictionary = {}) -> Array:
		return BoardUtils.find_path(grid, navigation_graph, enemy.position, target_cell, excluded_cells)


# Action execution mode.
enum Mode {
	# Evaluate each condition and choose an action based on a 
	# _random weighted choice.
	WEIGHT_BASED,
	
	# Execute _actions in order if their conditions are valid.
	# If the action has no valid conditions then do nothing.
	# The conditions ignore turn counters.
	ORDER_BASED
}


export(Mode) var mode: int = Mode.WEIGHT_BASED

# Max turn counter. After turn counter passes this value it is reset to zero,
# and the turn counter of all conditions is also reset.
# Oneshot conditions are not reset.
# If value is -1 then counter is never reset.
export(int, -1, 99) var max_turn_counter: int = -1

export(float, 0, 1, 0.1) var chance_to_move_to_enemy_during_move_behavior: float = 0.4
export(float, 0, 1, 0.1) var chance_to_select_random_top_result: float = 0.4
export(float, 0, 1, 0.1) var chance_to_move_after_using_skill: float = 0.2

export(int, 0, 5, 1) var max_number_of_random_top_results: int = 3


var _current_turn: int = 0
var _random: RandomNumberGenerator = RandomNumberGenerator.new()

var _actions: Array

var _action_index: int = 0

var _action: Action

var _pincer_target_cell: Cell

# Dictionary<Cell, bool>
var _pincer_excluded_cells: Dictionary


func _ready() -> void:
	_random.randomize()
	
	for action in get_children():
		if action is Action:
			_actions.push_back(action)
	
	assert(not _actions.empty(), "No actions")


func get_skills() -> Array:
	var skills: Dictionary = {}
	
	for action in get_children():
		if action is Action and action.skill != null:
			# Using dictionary as a set to avoid duplicates
			skills[action.skill] = true
	
	# TODO: Sort by name
	return skills.keys()


# Picks and action and saves it as a member so that other units can check
# the action that this unit will perform.
func pick_next_action(enemy: Enemy) -> void:
	if not enemy.has_active_delayed_skill:
		# A delayed skill won't increase the turn counter
		_current_turn += 1
		
		_action = _get_action(enemy)
		
		# Choosing a new action resets these values
		_pincer_target_cell = null
		_pincer_excluded_cells = {}
		
		if max_turn_counter != -1 and _current_turn >= max_turn_counter:
			_current_turn = 0
			
			_reset_actions_counters()


func execute_action(enemy: Enemy, grid: Grid, allies: Array, enemies: Array, allies_queue: Array) -> void:
	if enemy.has_active_delayed_skill:
		enemy.trigger_delayed_skill()
	else:
		if _action == null:
			enemy.emit_action_done()
		else:
			var action_parameters = ActionParameters.new()
			
			action_parameters.enemy = enemy
			action_parameters.grid = grid
			action_parameters.allies = _get_units_alive(allies)
			action_parameters.enemies = _get_units_alive(enemies)
			action_parameters.action = _action
			action_parameters.allies_queue = allies_queue
			
			action_parameters.build_navigation_graph()
			
			_execute_action(action_parameters)


func move_after_using_skill(enemy: Enemy, grid: Grid, enemies: Array) -> void:
	var action_parameters = ActionParameters.new()
	
	action_parameters.enemy = enemy
	action_parameters.grid = grid
	action_parameters.enemies = enemies
	
	action_parameters.build_navigation_graph()
	
	_move_to_chosen_cell(action_parameters)


func has_pincer_action() -> bool:
	return _action != null and \
		(_action.behavior == Action.Behavior.PINCER or \
	 	(_action.behavior == Action.Behavior.MOVE and not _action.has_valid_cell()))


func set_pincer_target_cell(target_cell: Cell, excluded_cell: Cell) -> void:
	_pincer_target_cell = target_cell
	_pincer_excluded_cells = {excluded_cell: true}


func _reset_actions_counters() -> void:
	for action in _actions:
		action.reset_turn_counter()


func _get_action(enemy: Enemy) -> Action:
	var current_hp_percentage: float = float(enemy.get_stats().health) / float(enemy.get_max_health())
	
	if mode == Mode.WEIGHT_BASED:
		return _get_random_weighted_action(current_hp_percentage)
	else:
		return _get_next_action(current_hp_percentage)


func _get_random_weighted_action(current_hp_percentage: float) -> Action:
	var possible_actions: Array = []
	var total_weights: int = 0
	
	for action in _actions:
		if action.can_activate(current_hp_percentage, _current_turn):
			possible_actions.push_back(action)
			
			total_weights += action.weight
			
			# Return early if you find an action that ignores weights
			if action.can_ignore_weights:
				return action
	
	if possible_actions.empty():
		return null
	
	# Random weighted choice
	var selection: int = _random.randi_range(0, total_weights)
	
	for i in range(possible_actions.size()):
		var weight: int = possible_actions[i].weight
		
		selection -= weight
		
		if selection <= 0:
			return possible_actions[i]
	
	return possible_actions.back()


func _get_next_action(current_hp_percentage: float) -> Action:
	if _actions.empty():
		return null
	
	if _action_index >= _actions.size():
		_action_index = 0
	
	var action: Action = _actions[_action_index]
	
	_action_index += 1
	
	# Don't use turn counter
	if action.can_activate(current_hp_percentage, _current_turn, false):
		return action
	else:
		return null


func _execute_action(action_parameters: ActionParameters) -> void:
	action_parameters.action.on_use()
	
	match(action_parameters.action.behavior):
		Action.Behavior.MOVE:
			_execute_move_action(action_parameters)
		Action.Behavior.USE_SKILL:
			_execute_skill_action(action_parameters)
		Action.Behavior.PINCER:
			assert(action_parameters.action.skill == null)
			
			_execute_pincer_action(action_parameters)
		_:
			action_parameters.enemy.emit_action_done()


func _execute_move_action(action_parameters: ActionParameters) -> void:
	assert(action_parameters.action.skill == null)
	
	if action_parameters.action.has_valid_cell():
		assert(_pincer_target_cell == null)
		
		var cell_position: Vector2 = action_parameters.action.get_cell_position()
		var next_cell: Cell = action_parameters.grid.get_cell_from_coordinates(cell_position)
		
		_move_to_given_cell(action_parameters, next_cell)
	elif _pincer_target_cell != null:
		print("Moving to pincer cell that was set up ", _pincer_target_cell.coordinates)
		
		_move_to_given_cell(action_parameters, _pincer_target_cell, _pincer_excluded_cells)
	else:
		_move_to_chosen_cell(action_parameters)


func _move_to_given_cell(action_parameters: ActionParameters, next_cell: Cell, excluded_cells: Dictionary = {}) -> void:
	if action_parameters.grid.get_cell_from_position(action_parameters.enemy.position) == next_cell:
		action_parameters.enemy.emit_action_done()
	else:
		var path: Array = action_parameters.find_path(next_cell, excluded_cells)
		
		if path.size() > 1:
			action_parameters.enemy.start_moving(path)
		else:
			_move_to_chosen_cell(action_parameters)


func _move_to_chosen_cell(action_parameters: ActionParameters) -> void:
	if _random.randf() < chance_to_move_to_enemy_during_move_behavior:
		_find_cell_close_to_enemy(action_parameters)
	else:
		_find_random_cell_to_move_to(action_parameters)


func _find_cell_close_to_enemy(action_parameters: ActionParameters) -> void:
	var candidate_cells: Array = _find_cells_close_to_enemies(action_parameters)
	
	var next_cell: Cell = null
	
	for cell in candidate_cells:
		if action_parameters.navigation_graph.has(cell):
			next_cell = cell
			
			break
	
	if next_cell == null:
		_find_random_cell_to_move_to(action_parameters)
	else:
		var path: Array = action_parameters.find_path(next_cell)
		
		action_parameters.enemy.start_moving(path)


# Returns Array<Cell>
# Finds free cells that neighbor enemies.
func _find_cells_close_to_enemies(action_parameters: ActionParameters) -> Array:
	var directions := [Cell.DIRECTION.RIGHT, Cell.DIRECTION.LEFT, Cell.DIRECTION.UP, Cell.DIRECTION.DOWN]
	var candidate_cells := []
	
	for enemy in action_parameters.enemies:
		var cell = action_parameters.grid.get_cell_from_position(enemy.position)
		
		for direction in directions:
			var neighbor: Cell = cell.get_neighbor(direction)
			
			if neighbor != null and neighbor.unit == null:
				candidate_cells.push_back(neighbor)
	
	return candidate_cells


# Find a _random cell to move to
func _find_random_cell_to_move_to(action_parameters: ActionParameters) -> void:
	var navigation_graph: Dictionary = action_parameters.navigation_graph
	
	var next_cell: Cell = navigation_graph.keys()[_random.randi_range(0, navigation_graph.size() - 1)]

	var path: Array = action_parameters.find_path(next_cell)
	
	action_parameters.enemy.start_moving(path)


func _execute_skill_action(action_parameters: ActionParameters) -> void:
	var action: Action = action_parameters.action
	
	assert(action.skill != null)
	
	var enemy: Unit = action_parameters.enemy
	
	var grid: Grid = action_parameters.grid
	
	if not action.can_move_when_using_skill:
		var target_cells: Array = $Evaluator.get_target_cells(enemy, enemy.position, action.skill, action_parameters.grid, action_parameters.allies, action_parameters.enemies)
		var path: Array = []
		
		enemy.use_skill(action.skill, target_cells, path)
	else:
		# Evaluate positions (requires having the whole graph)
		var results: Array = $Evaluator.evaluate_skill(enemy, grid, action_parameters.allies, action_parameters.enemies, action_parameters.navigation_graph, action.skill, action.preference)
		
		var top_result = results.front()
		
		# Pick a _random result to make it less predictable
		if results.size() > max_number_of_random_top_results and _random.randf() < chance_to_select_random_top_result:
			top_result = results[_random.randi_range(0, max_number_of_random_top_results)]
		
		# TODO: Use skill regardless?
		if top_result.damage_dealt == 0:
			_find_cell_close_to_enemy(action_parameters)
		else:
			var path: Array = action_parameters.find_path(top_result.cell)
			
			var can_move_after_using_skill: bool = _random.randf() < chance_to_move_after_using_skill
			
			action_parameters.enemy.use_skill(action.skill, top_result.target_cells, path, can_move_after_using_skill)


func _execute_pincer_action(action_parameters: ActionParameters) -> void:
	if action_parameters.allies.size() <= 1:
		print("No allies alive, can't pincer!")
		
		# TODO: Might be made redundant by swap and pincer
		_find_random_cell_to_move_to(action_parameters)
	elif _pincer_target_cell != null:
		print("Pincer action, moving to pincer that was set up")
		
		# FIXME: Don't repeat code from move_to_given_cell()
		if action_parameters.grid.get_cell_from_position(action_parameters.enemy.position) == _pincer_target_cell:
			action_parameters.enemy.emit_action_done()
		else:
			# TODO: If 2x2 exclude start cells
			# TODO: Verify that pincer is still valid (ally alive, no allies in 
			# pincered cells and at least one player unit alive in pincered cells)
			var path: Array = action_parameters.find_path(_pincer_target_cell, _pincer_excluded_cells)
			
			if path.size() > 1:
				action_parameters.enemy.start_moving(path)
			else:
				_find_pincer(action_parameters)
	else:
		_find_pincer(action_parameters)


func _find_pincer(action_parameters: ActionParameters) -> void:
	var possible_pincers: Array = $Evaluator.find_possible_pincers(action_parameters.enemy, action_parameters.grid, action_parameters.navigation_graph, action_parameters.allies)
	
	if possible_pincers.empty():
		_coordinate_pincer(action_parameters)
	else:
		var possible_pincer: PossiblePincer = possible_pincers.front()
		
		action_parameters.enemy.start_moving(possible_pincer.path_to_end_cell)


func _coordinate_pincer(action_parameters: ActionParameters) -> void:
	var coordinatable_pincers: Array =  $Evaluator.find_coordinated_pincers(action_parameters.enemy, action_parameters.grid, action_parameters.enemies, action_parameters.navigation_graph, action_parameters.allies_queue)
	
	if coordinatable_pincers.empty():
		# TODO: Swap and pincer
		_find_random_cell_to_move_to(action_parameters)
	else:
		var possible_pincer: PossiblePincer = coordinatable_pincers.front()
		
		print("Setting up a pincer ", possible_pincer.start_cell.coordinates, " to ", possible_pincer.end_cell.coordinates)
		
		possible_pincer.ally.set_pincer_target_cell(possible_pincer.start_cell, possible_pincer.end_cell)
		
		action_parameters.enemy.start_moving(possible_pincer.path_to_end_cell)


func _get_units_alive(units: Array) -> Array:
	var units_alive: Array = []
	
	for unit in units:
		if unit.is_alive():
			units_alive.push_back(unit)
	
	return units_alive
