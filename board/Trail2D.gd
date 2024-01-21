extends Node2D

export(int) var max_point_count: int = 20
export(int) var points_to_remove_when_adding_a_point: int = 8

# Number of interpolated points to add between the last added points and 
# the new point.
export(int) var interpolation_steps: int = 10

var last_stored_cell_point: Vector2 

var can_remove_faster: bool = false
var can_free_when_no_points_left: bool = false

onready var line_2d: Line2D = $AntialiasedLine2D


func _physics_process(_delta: float) -> void:
	if line_2d.get_point_count() > max_point_count or (line_2d.get_point_count() > 0 and can_remove_faster):
		_remove_points(1)
		
		_free_when_no_points_left()


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
		_remove_points(points_to_remove_when_adding_a_point)
	
	if $RemovalStartTimer.is_stopped():
		$RemovalStartTimer.start()
		
		can_remove_faster = false


func clear() -> void:
	line_2d.clear_points()


func queue_clear() -> void:
	can_free_when_no_points_left = true
	
	_free_when_no_points_left()


func set_gradient(gradient: Gradient) -> void:
	$AntialiasedLine2D.gradient = gradient


# Removes the given number of points, or the amount of points necessary to
# remove a sharp corner that is interpolation_steps away, whichever is greater
func _remove_points(points_to_remove: int) -> void:
	var points_to_sharp_angle: int = -1
	
	for i in range(0, interpolation_steps):
		if (i + 2) < line_2d.get_point_count():
			var vector_1: Vector2 = line_2d.get_point_position(i + 1) - line_2d.get_point_position(i)
			var vector_2: Vector2 = line_2d.get_point_position(i + 2) - line_2d.get_point_position(i + 1)
			
			var angle: float = abs(rad2deg(vector_1.angle_to(vector_2)))
			
			if _is_between(angle, 89, 91) or _is_between(angle, 134, 136) or _is_between(angle, 179, 181):
				points_to_sharp_angle = i + 2
				
				break
	
	for i in range(max(points_to_remove, points_to_sharp_angle)):
		if line_2d.get_point_count() > 0:
			line_2d.remove_point(0)


func _free_when_no_points_left() -> void:
	if line_2d.get_point_count() == 0 and can_free_when_no_points_left:
		queue_free()


func _is_between(value: float, low: float, high: float) -> bool:
	return low < value and value < high


func _on_RemovalStartTimer_timeout() -> void:
	can_remove_faster = true
