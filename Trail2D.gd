extends Line2D

export(int) var max_point_count: int = 20
export(int) var interpolation_steps: int = 10

var last_stored_cell_point: Vector2 

var can_remove_faster: bool = false


func _physics_process(delta):
	if get_point_count() > max_point_count or (get_point_count() > 0 and can_remove_faster):
		remove_point(0)


func add(point: Vector2) -> void:
	if not last_stored_cell_point.is_equal_approx(point):
		if get_point_count() > 0:
			for i in range(1, interpolation_steps):
				var weight: float = float(i) / float(interpolation_steps)
				
				var interpolated_point := last_stored_cell_point.linear_interpolate(point, weight)
				
				add_point(interpolated_point)
		
		add_point(point)
		
		last_stored_cell_point = point
	
	if get_point_count() > max_point_count:
		for i in range(get_point_count() - max_point_count - 5):
			remove_point(0)
	
	if $RemovalStartTimer.is_stopped():
		$RemovalStartTimer.start()
		
		can_remove_faster = false


func clear() -> void:
	clear_points()


func _on_RemovalStartTimer_timeout() -> void:
	can_remove_faster = true
