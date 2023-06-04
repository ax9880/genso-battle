extends Unit

export var turn_counter: int = 1

onready var turn_counter_max_value: int = turn_counter

signal action_done
signal started_moving(unit)

# Array of Vector2
var path := []


func act(grid: Grid) -> void:
	if turn_counter > 0:
		turn_counter -= 1
	
	if turn_counter == 0:
		turn_counter = turn_counter_max_value
		
		# Build graph
		var navigation_graph: Dictionary = grid.build_navigation_graph(self.position, Grid.ENEMY_GROUP)
		
		# Evaluate positions (requires having the whole graph)
		var i = 0
		
		var target_cell: CellArea2D = null
		
		# Pick one
		for node in navigation_graph.keys():
			i += 1
			
			if i > 6:
				target_cell = node
				break
		
		path = grid.find_path(navigation_graph, position, target_cell)
		
		# Move or perform skill (in any order)
		_start_moving()
	else:
		emit_signal("action_done")


func _start_moving() -> void:
	_increase_sprite_size()
	
	_move()
	
	emit_signal("started_moving", self)
	
	enable_swap_area()


func _move_towards_mouse() -> void:
	pass


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
		emit_signal("action_done")
		
		# Use state in Enemy?
		self.current_state = STATE.IDLE
		
		_restore_sprite_size()


func _find_path(navigation_graph: Dictionary) -> void:
	return


func _on_Tween_tween_completed(_object: Object, key: String):
	if key == ":position":
		_move()
