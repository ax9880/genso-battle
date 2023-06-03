extends Unit


class GraphCell extends Reference:
	var cell: CellArea2D
	var parent: GraphCell


class Graph extends Reference:
	var adjacency_list: Array


export var turn_counter: int = 1

onready var turn_counter_max_value: int = turn_counter

signal action_done
signal started_moving(unit)

# Array of Vector2
var path := []


func decrease_turn_counter() -> void:
	if turn_counter > 0:
		turn_counter -= 1
	
	if turn_counter == 0:
		turn_counter = turn_counter_max_value
		path.push_back(Vector2(50, 50))
		path.push_back(Vector2(50, 150))
		
		_start_moving()
	else:
		emit_signal("action_done")


func _start_moving() -> void:
	_move()
	
	emit_signal("started_moving", self)
	
	enable_swap_area()
	_increase_sprite_size()

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


func _build_graph(grid: Array) -> void:
	# _get_cell()
	var cell: Vector2 = Vector2.ZERO
	
	var start_cell: CellArea2D = grid[cell.x][cell.y]
	
	var queue := []
	
	queue.push_back(start_cell)


func _on_Tween_tween_completed(_object: Object, key: String):
	if key == ":position":
		_move()
