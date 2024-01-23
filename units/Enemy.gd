extends Unit

class_name Enemy


export var turn_counter: int = 1 setget set_turn_counter
export var chance_to_move_to_enemy_during_move_behavior: float = 0.8

var turn_counter_max_value: int

var can_use_skill_after_moving := false
var is_moving := false
var selected_skill: Skill
var selected_skill_target_cells: Array
var has_active_delayed_skill: bool = false

# Array of Vector2
var path := []

signal action_done
signal started_moving(unit)
signal use_skill(unit, skill, target_cells)

# Unit, Skill, Array
signal use_delayed_skill(unit, skill, target_cells)


func _ready() -> void:
	turn_counter_max_value = get_stats().max_turn_counter


func act(grid: Grid, allies: Array, enemies: Array) -> void:
	if not can_act():
		print("Enemy %s can not act", name)
		
		emit_action_done()
	else:
		if is_controlled_by_player:
			_enable_player_control()
		else:
			if turn_counter > 0:
				self.turn_counter = turn_counter - 1
			
			can_use_skill_after_moving = false
			is_moving = false
			
			if turn_counter == 0:
				$AIController.find_next_move(self, grid, allies, enemies)
			else:
				print("Enemy %s can't act yet" % name)
				
				emit_action_done()


func _enable_player_control() -> void:
	enable_selection_area()
	
	$CanvasLayer/UnitName.show()
	$CanvasLayer/UnitName.modulate = Color.white


func use_skill(skill: Skill, target_cells: Array, _path: Array) -> void:
	selected_skill = skill
	selected_skill_target_cells = target_cells
	path = _path
	
	if path.size() > 1:
		can_use_skill_after_moving = true
		
		_start_moving()
	else:
		_use_skill()


func trigger_delayed_skill() -> void:
	assert(has_active_delayed_skill)
	
	_use_skill()
	
	has_active_delayed_skill = false


# Before calling this method set selected_skill and selected_skill_target_cells
func _use_skill() -> void:
	if selected_skill != null and can_act():
		if selected_skill.is_delayed and not has_active_delayed_skill:
			has_active_delayed_skill = true
			
			emit_signal("use_delayed_skill", self, selected_skill, selected_skill_target_cells)
		else:
			emit_signal("use_skill", self, selected_skill, selected_skill_target_cells)
			
			has_active_delayed_skill = false
	else:
		emit_action_done()


func start_moving(_path: Array) -> void:
	path = _path
	
	_start_moving()


func _start_moving() -> void:
	if current_state == STATE.SWAPPING:
		# Wait for tween to end before you start moving (see signal callback)
		# Otherwise you might start moving from the wrong cell, because the active
		# cell is determined from the position of the unit (this is a problem of
		# the unit not having a reference to its cell)
		return
	
	if path.size() <= 1:
		# Path points to current cell
		emit_action_done()
	else:
		is_moving = true
		
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
		release()
		
		path.clear()


func _execute_after_move() -> void:
	if can_use_skill_after_moving:
		_use_skill()
	else:
		emit_action_done()


func reset_turn_counter() -> void:
	if turn_counter <= 0:
		self.turn_counter = turn_counter_max_value


func release() -> void:
	if not path.empty() and $Tween.is_active():
		$Tween.stop(self, ":position")
	
	.release()
	
	if is_controlled_by_player:
		$CanvasLayer/UnitName.hide()


func set_turn_counter(value: int) -> void:
	turn_counter = value
	
	$Control/Container/TurnCount.text = str(turn_counter)


func emit_action_done() -> void:
	emit_signal("action_done", self)
	
	can_use_skill_after_moving = false
	is_moving = false
	
	path.clear()


func _on_snap_to_grid() -> void:
	._on_snap_to_grid()
	
	if is_moving:
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
				
				if !path.empty():
					_start_moving()
