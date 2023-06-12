extends Unit

export var turn_counter: int = 1 setget set_turn_counter

var turn_counter_max_value: int

signal action_done
signal started_moving(unit)
signal use_skill(unit, skill)

var can_use_skill_after_moving := false
var selected_skill: Skill

# Array of Vector2
var path := []


func _ready() -> void:
	turn_counter_max_value = get_stats().max_turn_counter


func act(grid: Grid, allies: Array, enemies: Array) -> void:
	if is_dead():
		emit_signal("action_done", self)
	else:
		if is_controlled_by_player:
			enable_selection_area()
			
			$CanvasLayer/UnitName.show()
			$CanvasLayer/UnitName.modulate = Color.white
		else:
			if turn_counter > 0:
				self.turn_counter = turn_counter - 1
			
			if turn_counter == 0:
				_find_next_move(grid, allies, enemies)
			else:
				emit_signal("action_done", self)


func _find_next_move(grid: Grid, allies: Array, enemies: Array) -> void:
	var navigation_graph: Dictionary = BoardUtils.build_navigation_graph(grid, position, faction, get_stats().movement_range)
	
	selected_skill = $Job.skills.front()
	
	# Evaluate positions (requires having the whole graph)
	var results = $AIController.evaluate_skill(self, selected_skill, grid, navigation_graph)
	
	var top_result = results.front()
	
	print("Estimated damage dealt: %d" % top_result.damage_dealt)
	top_result.cell.modulate = Color.red
	
	path = BoardUtils.find_path(grid, navigation_graph, position, top_result.cell)
	
	if !path.empty():
		# Move or perform skill (in any order)
		can_use_skill_after_moving = true
		
		_start_moving()
	else:
		_use_skill(selected_skill)


func _use_skill(skill: Skill) -> void:
	if skill != null:
		emit_signal("use_skill", self, skill)
	else:
		emit_signal("action_done", self)


func _start_moving() -> void:
	if current_state == STATE.SWAPPING:
		# Wait for tween to end before you start moving (see signal callback)
		# Otherwise you might start moving from the wrong cell, because the active
		# cell is determined from the position of the unit (this is a problem of
		# the unit not having a reference to its cell)
		return

	emit_signal("started_moving", self)
	
	self.current_state = STATE.PICKED_UP
	
	_move()


func _move() -> void:
	var target_position = path.pop_front()
	
	if target_position != null:
		var tween_time_seconds: float = Utils.calculate_time(position, target_position, swap_velocity_pixels_per_second)
		
		tween.interpolate_property(self, "position",
					position, target_position,
					tween_time_seconds,
					Tween.TRANS_LINEAR)
			
		tween.start()
	else:
		self.current_state = STATE.IDLE
		
		path = []
		
		if can_use_skill_after_moving:
			_use_skill(selected_skill)
		else:
			emit_signal("action_done", self)


func reset_turn_counter() -> void:
	if turn_counter <= 0:
		self.turn_counter = turn_counter_max_value


func release() -> void:
	.release()
	
	if is_controlled_by_player:
		disable_selection_area()
		
		$CanvasLayer/UnitName.hide()


func set_turn_counter(value: int) -> void:
	turn_counter = value
	
	$Control/Container/TurnCount.text = str(turn_counter)


func _on_snap_to_grid() -> void:
	._on_snap_to_grid()
	
	emit_signal("action_done", self)


func _on_Tween_tween_completed(_object: Object, key: String) -> void:
	match(current_state):
		STATE.PICKED_UP:
			if key == ":position":
				_move()
		STATE.SNAPPING_TO_GRID:
			if key == ":position":
				_on_snap_to_grid()
		STATE.SWAPPING:
			if key == ":position":
				self.current_state = STATE.IDLE
				
				if !path.empty():
					_start_moving()
