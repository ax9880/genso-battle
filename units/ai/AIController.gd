extends Node


export(float, 0, 1, 0.1) var chance_to_move_to_enemy_during_move_behavior: float


var current_turn: int = 0
var random: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	random.randomize()


func get_skills() -> Array:
	return []


func find_next_move(unit: Unit, grid: Grid, allies: Array, enemies: Array) -> void:
	current_turn += 1
	
	if unit.has_active_delayed_skill:
		unit.trigger_delayed_skill()
	else:
		var action: Action = _get_next_action(unit)
		
		if action == null:
			unit.emit_action_done()
		else:
			_execute_action(unit, grid, allies, enemies, action)


func _get_next_action(unit: Unit) -> Action:
	assert(get_child_count() > 0)
	
	var actions: Array = []
	var total_weights: int = 0
	var current_hp_percentage: float = float(unit.get_stats().health) / float(unit.get_max_health())
	
	print("current_hp_percentage: %f" % current_hp_percentage)
	
	for action in get_children():
		if action.has_method("can_activate") and  action.can_activate(current_hp_percentage, current_turn):
			actions.push_back(action)
			
			total_weights += action.weight
			
			# Return early if you find an action that ignores weights
			if action.can_ignore_weights:
				return action
	
	if actions.empty():
		return null
	
	# Random weighted choice
	var selection: int = random.randi_range(0, total_weights)
	
	for i in range(actions.size()):
		var weight: int = actions[i].weight
		
		selection -= weight
		
		if selection <= 0:
			return actions[i]
	
	return actions.back()


func _execute_action(unit: Unit, grid: Grid, allies: Array, enemies: Array, action: Action) -> void:
	action.on_use()
	
	var navigation_graph: Dictionary = BoardUtils.build_navigation_graph(grid, unit.position, unit.faction, unit.get_stats().movement_range)
	
	match(action.behavior):
		Action.Behavior.MOVE:
			_move_to_cell_or_enemy(unit, grid, enemies, action, navigation_graph)
		Action.Behavior.USE_SKILL:
			_use_skill(unit, grid, allies, enemies, action, navigation_graph)
		Action.Behavior.PINCER:
			assert(action.skill == null)
			
			_find_pincer(unit, grid, allies, enemies, navigation_graph)
		_:
			unit.emit_action_done()


func _move_to_cell_or_enemy(unit: Unit, grid: Grid, enemies: Array, action: Action, navigation_graph: Dictionary) -> void:
	assert(action.skill == null)
	
	if action.has_valid_cell():
		_move_to_given_cell(unit, grid, enemies, action, navigation_graph)
	else:
		if random.randf() < chance_to_move_to_enemy_during_move_behavior:
			_find_cell_close_to_enemy(unit, grid, enemies, navigation_graph)
		else:
			_find_cell_to_move_to(unit, grid, navigation_graph)


func _move_to_given_cell(unit: Unit, grid: Grid, enemies: Array, action: Action, navigation_graph: Dictionary) -> void:
	var cell_position: Vector2 = action.get_cell_position()
	
	var next_cell: Cell = grid.get_cell_from_position(cell_position)
	
	if grid.get_cell_from_position(unit.position) == next_cell:
		unit.emit_action_done()
	else:
		var path: Array = BoardUtils.find_path(grid, navigation_graph, unit.position, next_cell)
		
		if path.size() > 1:
			unit.start_moving(path)
		else:
			_find_cell_to_move_to(unit, grid, navigation_graph)


func _find_cell_close_to_enemy(unit: Unit, grid: Grid, enemies: Array, navigation_graph: Dictionary) -> void:
	var candidate_cells: Array = _find_cells_close_to_enemies(unit, grid, enemies)
	
	var next_cell: Cell = null
	
	for cell in candidate_cells:
		if navigation_graph.has(cell):
			next_cell = cell
			
			break
	
	if next_cell == null:
		_find_cell_to_move_to(unit, grid, navigation_graph)
	else:
		var path: Array = BoardUtils.find_path(grid, navigation_graph, unit.position, next_cell)
		
		unit.start_moving(path)


# Returns Array<Cell>
# Finds free cells that neighbor enemies.
func _find_cells_close_to_enemies(unit: Unit, grid: Grid, enemies: Array) -> Array:
	var directions := [Cell.DIRECTION.RIGHT, Cell.DIRECTION.LEFT, Cell.DIRECTION.UP, Cell.DIRECTION.DOWN]
	var candidate_cells := []
	
	for unit in enemies:
		var cell = grid.get_cell_from_position(unit.position)
		
		for direction in directions:
			var neighbor: Cell = cell.get_neighbor(direction)
			
			if neighbor != null and neighbor.unit == null:
				candidate_cells.push_back(neighbor)
	
	return candidate_cells


# Find a random cell to move to
func _find_cell_to_move_to(unit: Unit, grid: Grid, navigation_graph: Dictionary) -> void:
	var next_cell: Cell = navigation_graph.keys()[random.randi_range(0, navigation_graph.size() - 1)]

	var path: Array = BoardUtils.find_path(grid, navigation_graph, unit.position, next_cell)
	
	unit.start_moving(path)


func _use_skill(unit: Unit, grid: Grid, allies: Array, enemies: Array, action: Action, navigation_graph: Dictionary) -> void:
	assert(action.skill != null)
	
	if action.has_valid_cell():
		if action.can_use_skill_after_moving:
			# TODO: find path to cell
			# TODO: Use skill after moving
			pass
		
		pass
	else:
		# Evaluate positions (requires having the whole graph)
		var results: Array = $Evaluator.evaluate_skill(unit, grid, allies, enemies, navigation_graph, action.skill)
		
		var top_result = results.front()
		
		# Pick a random result to make it less predictable
		# TODO: Add constants / export vars
		if results.size() > 3 and random.randf() < 0.4:
			top_result = results[random.randi_range(0, 3)]
		
		# TODO: Use skill regardless?
		if top_result.damage_dealt == 0:
			_find_cell_close_to_enemy(unit, grid, enemies, navigation_graph)
		else:
			var path: Array = BoardUtils.find_path(grid, navigation_graph, unit.position, top_result.cell)
			
			unit.use_skill(action.skill, top_result.target_cells, path)


func _find_pincer(unit: Unit, grid: Grid, allies: Array, enemies: Array, navigation_graph: Dictionary) -> void:
	var possible_pincers: Array = $Evaluator.find_possible_pincers(unit, grid, allies)

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
		_find_cell_close_to_enemy(unit, grid, enemies, navigation_graph)
	else:
		var path: Array = BoardUtils.find_path(grid, navigation_graph, unit.position, next_cell)
		
		unit.start_moving(path)
