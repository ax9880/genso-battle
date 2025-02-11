class_name Enemy
extends Unit


signal action_done(unit)
signal started_moving(unit)
signal use_skill(unit, skill, target_cells)

# Unit, Skill, Array
signal use_delayed_skill(unit, skill, target_cells)

export var turn_counter: int = 1 setget set_turn_counter
export var chance_to_move_to_enemy_during_move_behavior: float = 0.8

var _turn_counter_max_value: int

var _can_use_skill_after_moving := false
var _is_moving := false
var _selected_skill: Skill
var _selected_skill_target_cells: Array
var _can_move_after_using_skill := false

var has_active_delayed_skill: bool = false

# Array of Vector2
var _path := []


func _ready() -> void:
	$Job.set_level(level)
	
	_turn_counter_max_value = get_stats().max_turn_counter


# allies_queue is a queue of the units that will act after this one
func act(grid: Grid, allies: Array, enemies: Array, allies_queue: Array) -> void:
	if not can_act():
		print("Enemy %s can not act" % name)
		
		emit_action_done()
	else:
		if is_controlled_by_player:
			_enable_player_control()
		else:
			if turn_counter > 0:
				self.turn_counter = turn_counter - 1
			
			_can_use_skill_after_moving = false
			_is_moving = false
			
			if turn_counter == 0:
				if current_state != STATE.IDLE:
					print("Enemy %s waiting for _tween to end" % name)
					
					yield(_tween, "tween_all_completed")
				
				$AIController.execute_action(self, grid, allies, enemies, allies_queue)
			else:
				print("Enemy %s can't act yet" % name)
				
				emit_action_done()


func pick_next_action() -> void:
	# When it's 1 or 0 (turn 0) that means this unit will act in this turn
	if turn_counter <= 1:
		$AIController.pick_next_action(self)
	else:
		$AIController.clear_action()


func has_pincer_action() -> bool:
	return $AIController.has_pincer_action()


func can_coordinate_pincer() -> bool:
	return $AIController.can_coordinate_pincer()


func set_pincer(start_cell: Cell, end_cell: Cell, pincered_cells: Array) -> void:
	$AIController.set_pincer(start_cell, end_cell, pincered_cells, is2x2())


func on_skill_used(grid: Grid, enemies: Array) -> void:
	if _can_move_after_using_skill:
		_clear_flags()
		
		$AIController.move_after_using_skill(self, grid, enemies)
	else:
		emit_action_done()


func _enable_player_control() -> void:
	enable_selection_area()
	
	$CanvasLayer/UnitName.show()
	$CanvasLayer/UnitName.modulate = Color.white


func use_skill(skill: Skill, target_cells: Array, path: Array, can_move_after_using_skill: bool = false) -> void:
	_selected_skill = skill
	_selected_skill_target_cells = target_cells
	_path = path
	_can_move_after_using_skill = can_move_after_using_skill
	
	if _path.size() > 1:
		_can_use_skill_after_moving = true
		
		_start_moving()
	else:
		_use_skill()


func trigger_delayed_skill() -> void:
	assert(has_active_delayed_skill)
	
	_use_skill()
	
	has_active_delayed_skill = false


# Before calling this method set _selected_skill and _selected_skill_target_cells
func _use_skill() -> void:
	if _selected_skill != null and can_act():
		if _selected_skill.is_delayed and not has_active_delayed_skill:
			has_active_delayed_skill = true
			
			emit_signal("use_delayed_skill", self, _selected_skill, _selected_skill_target_cells)
		else:
			emit_signal("use_skill", self, _selected_skill, _selected_skill_target_cells)
			
			has_active_delayed_skill = false
	else:
		emit_action_done()


func start_moving(path: Array) -> void:
	_path = path
	
	_start_moving()


func _start_moving() -> void:
	if current_state == STATE.SWAPPING:
		# Wait for _tween to end before you start moving (see signal callback)
		# Otherwise you might start moving from the wrong cell, because the active
		# cell is determined from the position of the unit (this is a problem of
		# the unit not having a reference to its cell)
		return
	
	if _path.size() <= 1:
		# Path points to current cell
		emit_action_done()
	else:
		_is_moving = true
		
		emit_signal("started_moving", self)
		
		self.current_state = STATE.PICKED_UP
		
		_move()


func _move() -> void:
	var target_position = _path.pop_front()
	
	if target_position != null:
		var tween_time_seconds: float = Utils.calculate_time(position, target_position, swap_velocity_pixels_per_second)
		
		_tween.interpolate_property(self, "position",
					position, target_position,
					tween_time_seconds,
					Tween.TRANS_LINEAR)
			
		_tween.start()
	else:
		release()
		
		_path.clear()


func _execute_after_move() -> void:
	if _can_use_skill_after_moving:
		_use_skill()
	else:
		emit_action_done()


func reset_turn_counter() -> void:
	if turn_counter <= 0:
		if get_stats().can_randomize_turn_counter:
			self.turn_counter = _random.randi_range(1, _turn_counter_max_value)
		else:
			self.turn_counter = _turn_counter_max_value


func release() -> void:
	if not _path.empty() and _tween.is_active():
		_tween.stop(self, "position")
	
	.release()
	
	if is_controlled_by_player:
		$CanvasLayer/UnitName.hide()


func set_turn_counter(value: int) -> void:
	turn_counter = value
	
	$Control/Container/TurnCount.text = str(turn_counter)


func emit_action_done() -> void:
	emit_signal("action_done", self)
	
	_clear_flags()
	
	_path.clear()


func _clear_flags() -> void:
	_can_use_skill_after_moving = false
	_is_moving = false
	_can_move_after_using_skill = false


func _on_snap_to_grid() -> void:
	._on_snap_to_grid()
	
	if _is_moving:
		_execute_after_move()
	else:
		# Called when unit is controlled by player?
		
		print("Enemy action done")
		
		emit_action_done()


func get_skills() -> Array:
	return $AIController.get_skills()


## Signals

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
				
				if !_path.empty():
					_start_moving()
