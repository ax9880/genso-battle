extends Unit

export var turn_counter: int = 1 setget set_turn_counter

var turn_counter_max_value: int

signal action_done
signal started_moving(unit)
signal use_skill(unit, skill)

# Array of Vector2
var path := []


func _ready() -> void:
	turn_counter_max_value = get_stats().max_turn_counter


func act(board: Board) -> void:
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
				_find_next_move(board)
			else:
				emit_signal("action_done", self)


func _find_next_move(board: Board) -> void:
	var navigation_graph: Dictionary = board.build_navigation_graph(position, faction, get_stats().movement_range)
	
	# Evaluate positions (requires having the whole graph)
	var i = 0
	
	var target_cell: Cell = null
	
	# Pick one
	for node in navigation_graph.keys():
		i += 1
		
		if i > 4:
			target_cell = node
			break
	
	path = board.find_path(navigation_graph, position, target_cell)
	
	if !path.empty():
		# Move or perform skill (in any order)
		_use_skill()
		
		#_start_moving()
	else:
		emit_signal("action_done", self)


func _use_skill() -> void:
	var skill: Skill = $Job.skills.front()
	
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
		
		# TODO: Reset the turn counter after the pincers are done
		path = []
		
		emit_signal("action_done", self)


func reset_turn_counter() -> void:
	if turn_counter <= 0:
		self.turn_counter = turn_counter_max_value


func release() -> void:
	.release()
	
	if is_controlled_by_player:
		emit_signal("action_done", self)
		
		disable_selection_area()
		
		$CanvasLayer/UnitName.hide()


func set_turn_counter(value: int) -> void:
	turn_counter = value
	
	$CanvasLayer/Container/TurnCount.text = str(turn_counter)


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
