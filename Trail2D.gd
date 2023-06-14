extends Node2D

export(int) var max_point_count: int = 20
export(int) var interpolation_steps: int = 10

var last_stored_cell_point: Vector2 

var can_remove_faster: bool = false

onready var line_2d: Line2D = $AntialiasedLine2D


func _physics_process(delta):
	if line_2d.get_point_count() > max_point_count or (line_2d.get_point_count() > 0 and can_remove_faster):
		line_2d.remove_point(0)


func add(point: Vector2) -> void:
	if not last_stored_cell_point.is_equal_approx(point):
		if line_2d.get_point_count() > 0:
			for i in range(1, interpolation_steps):
				var weight: float = float(i) / float(interpolation_steps)
				
				var interpolated_point := last_stored_cell_point.linear_interpolate(point, weight)
				
				line_2d.add_point(interpolated_point)
		
		line_2d.add_point(point)
		
		last_stored_cell_point = point
	
	if line_2d.get_point_count() > max_point_count:
		for i in range(line_2d.get_point_count() - max_point_count - 5):
			line_2d.remove_point(0)
	
	if $RemovalStartTimer.is_stopped():
		$RemovalStartTimer.start()
		
		can_remove_faster = false


func clear() -> void:
	line_2d.clear_points()


func _on_RemovalStartTimer_timeout() -> void:
	can_remove_faster = true
