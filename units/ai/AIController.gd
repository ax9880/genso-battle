extends Node


# Action execution mode.
enum Mode {
	# Evaluate each condition and choose an action based on a 
	# random weighted choice.
	WEIGHT_BASED,
	
	# Execute actions in order if their conditions are valid.
	# If the action has no valid conditions then do nothing.
	# The conditions ignore turn counters.
	ORDER_BASED
}


export(Mode) var mode: int = Mode.WEIGHT_BASED

export(float, 0, 1, 0.1) var chance_to_move_to_enemy_during_move_behavior: float = 0.0
export(float, 0, 1, 0.1) var chance_to_select_random_top_result: float = 0.0
export(int, 0, 5, 1) var max_number_of_random_top_results: float = 3


var current_turn: int = 0
var random: RandomNumberGenerator = RandomNumberGenerator.new()

var actions: Array

var action_index: int = 0


func _ready() -> void:
	random.randomize()
	
	for action in get_children():
		if action is Action:
			actions.push_back(action)
	
	assert(not actions.empty(), "No actions")


func get_skills() -> Array:
	var skills: Dictionary = {}
	
	for action in get_children():
		if action is Action and action.skill != null:
			# Using dictionary as a set to avoid duplicates
			skills[action.skill] = true
	
	# TODO: Sort by name
	return skills.keys()


func find_next_move(enemy: Enemy, grid: Grid, allies: Array, enemies: Array) -> void:
	if enemy.has_active_delayed_skill:
		# A delayed skill won't increase the turn counter
		enemy.trigger_delayed_skill()
	else:
		current_turn += 1
		
		var action: Action = _get_action(enemy)
		
		if action == null:
			enemy.emit_action_done()
		else:
			_execute_action(enemy, grid, allies, enemies, action)


func _get_action(enemy: Enemy) -> Action:
	var current_hp_percentage: float = float(enemy.get_stats().health) / float(enemy.get_max_health())
	
	if mode == Mode.WEIGHT_BASED:
		return _get_random_weighted_action(enemy, current_hp_percentage)
	else:
		return _get_next_action(enemy, current_hp_percentage)


func _get_random_weighted_action(enemy: Enemy, current_hp_percentage: float) -> Action:
	var possible_actions: Array = []
	var total_weights: int = 0
	
	for action in actions:
		if action is Action and action.can_activate(current_hp_percentage, current_turn):
			possible_actions.push_back(action)
			
			total_weights += action.weight
			
			# Return early if you find an action that ignores weights
			if action.can_ignore_weights:
				return action
	
	if possible_actions.empty():
		return null
	
	# Random weighted choice
	var selection: int = random.randi_range(0, total_weights)
	
	for i in range(possible_actions.size()):
		var weight: int = possible_actions[i].weight
		
		selection -= weight
		
		if selection <= 0:
			return possible_actions[i]
	
	return possible_actions.back()


func _get_next_action(enemy: Enemy, current_hp_percentage: float) -> Action:
	if actions.empty():
		return null
	
	if action_index >= actions.size():
		action_index = 0
	
	var action: Action = actions[action_index]
	
	action_index += 1
	
	# Don't use turn counter
	if action.can_activate(current_hp_percentage, current_turn, false):
		return action
	else:
		return null


func _execute_action(enemy: Enemy, grid: Grid, allies: Array, enemies: Array, action: Action) -> void:
	action.on_use()
	
	var navigation_graph: Dictionary = BoardUtils.build_navigation_graph(grid, enemy.position, enemy.faction, enemy.get_stats().movement_range)
	
	match(action.behavior):
		Action.Behavior.MOVE:
			_execute_move_action(enemy, grid, enemies, action, navigation_graph)
		Action.Behavior.USE_SKILL:
			_execute_skill_action(enemy, grid, allies, enemies, action, navigation_graph)
		Action.Behavior.PINCER:
			assert(action.skill == null)
			
			_execute_pincer_action(enemy, grid, allies, enemies, navigation_graph)
		_:
			enemy.emit_action_done()


func _execute_move_action(enemy: Enemy, grid: Grid, enemies: Array, action: Action, navigation_graph: Dictionary) -> void:
	assert(action.skill == null)
	
	if action.has_valid_cell():
		_move_to_given_cell(enemy, grid, enemies, action, navigation_graph)
	else:
		if random.randf() < chance_to_move_to_enemy_during_move_behavior:
			_find_cell_close_to_enemy(enemy, grid, enemies, navigation_graph)
		else:
			_find_random_cell_to_move_to(enemy, grid, navigation_graph)


func _move_to_given_cell(enemy: Enemy, grid: Grid, enemies: Array, action: Action, navigation_graph: Dictionary) -> void:
	var cell_position: Vector2 = action.get_cell_position()
	
	var next_cell: Cell = grid.get_cell_from_coordinates(cell_position)
	
	if grid.get_cell_from_position(enemy.position) == next_cell:
		enemy.emit_action_done()
	else:
		var path: Array = BoardUtils.find_path(grid, navigation_graph, enemy.position, next_cell)
		
		if path.size() > 1:
			enemy.start_moving(path)
		else:
			_find_random_cell_to_move_to(enemy, grid, navigation_graph)


func _find_cell_close_to_enemy(enemy: Enemy, grid: Grid, enemies: Array, navigation_graph: Dictionary) -> void:
	var candidate_cells: Array = _find_cells_close_to_enemies(enemy, grid, enemies)
	
	var next_cell: Cell = null
	
	for cell in candidate_cells:
		if navigation_graph.has(cell):
			next_cell = cell
			
			break
	
	if next_cell == null:
		_find_random_cell_to_move_to(enemy, grid, navigation_graph)
	else:
		var path: Array = BoardUtils.find_path(grid, navigation_graph, enemy.position, next_cell)
		
		enemy.start_moving(path)


# Returns Array<Cell>
# Finds free cells that neighbor enemies.
func _find_cells_close_to_enemies(enemy: Enemy, grid: Grid, enemies: Array) -> Array:
	var directions := [Cell.DIRECTION.RIGHT, Cell.DIRECTION.LEFT, Cell.DIRECTION.UP, Cell.DIRECTION.DOWN]
	var candidate_cells := []
	
	for enemy in enemies:
		var cell = grid.get_cell_from_position(enemy.position)
		
		for direction in directions:
			var neighbor: Cell = cell.get_neighbor(direction)
			
			if neighbor != null and neighbor.unit == null:
				candidate_cells.push_back(neighbor)
	
	return candidate_cells


# Find a random cell to move to
func _find_random_cell_to_move_to(enemy: Enemy, grid: Grid, navigation_graph: Dictionary) -> void:
	var next_cell: Cell = navigation_graph.keys()[random.randi_range(0, navigation_graph.size() - 1)]

	var path: Array = BoardUtils.find_path(grid, navigation_graph, enemy.position, next_cell)
	
	enemy.start_moving(path)


func _execute_skill_action(enemy: Enemy, grid: Grid, allies: Array, enemies: Array, action: Action, navigation_graph: Dictionary) -> void:
	assert(action.skill != null)
	
	if not action.can_move_when_using_skill:
		var target_cells: Array = $Evaluator.get_target_cells(enemy, enemy.position, action.skill, grid, allies, enemies)
		var path: Array = []
		
		enemy.use_skill(action.skill, target_cells, path)
	else:
		# Evaluate positions (requires having the whole graph)
		var results: Array = $Evaluator.evaluate_skill(enemy, grid, allies, enemies, navigation_graph, action.skill, action.preference)
		
		var top_result = results.front()
		
		# Pick a random result to make it less predictable
		if results.size() > max_number_of_random_top_results and random.randf() < chance_to_select_random_top_result:
			top_result = results[random.randi_range(0, max_number_of_random_top_results)]
		
		# TODO: Use skill regardless?
		if top_result.damage_dealt == 0:
			_find_cell_close_to_enemy(enemy, grid, enemies, navigation_graph)
		else:
			var path: Array = BoardUtils.find_path(grid, navigation_graph, enemy.position, top_result.cell)
			
			enemy.use_skill(action.skill, top_result.target_cells, path)


func _execute_pincer_action(enemy: Enemy, grid: Grid, allies: Array, enemies: Array, navigation_graph: Dictionary) -> void:
	var possible_pincers: Array = $Evaluator.find_possible_pincers(enemy, grid, allies)
	
	var next_cell: Cell = null
	
	# Finds the best and first cell that it can navigate to (i.e. it is in
	# the navigation graph)
	for possible_pincer in possible_pincers:
		if navigation_graph.has(possible_pincer.cell):
			next_cell = possible_pincer.cell
			
			break
	
	if next_cell == null:
		# Move to a cell to try to set up a pincer
		# Possible to use a skill? Not very simple
		# Maybe add a node path to action so it has a fallback action?
		_find_cell_close_to_enemy(enemy, grid, enemies, navigation_graph)
	else:
		var path: Array = BoardUtils.find_path(grid, navigation_graph, enemy.position, next_cell)
		
		enemy.start_moving(path)
