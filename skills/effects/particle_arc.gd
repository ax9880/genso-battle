extends Node2D


signal target_reached

export(float) var trail_velocity_pixels_per_second := 1200.0
export(float) var displacement_time_seconds := 0.2

# If true, the _tween time is fixed and the velocity of the trail will
# be determined by the _tween automatically.
export(bool) var is_tween_fixed_time := true

export(float) var arc_height := 100.0

export(NodePath) var particles_node_path: NodePath

var _particles: CPUParticles2D
var _total_tween_time_seconds: float

onready var _tween := $Tween


func _ready() -> void:
	 _particles = get_node(particles_node_path)


func play(start_position: Vector2, target_position: Vector2) -> void:
	_particles.emitting = true
	
	var distance: float = start_position.distance_to(target_position)
	
	if is_tween_fixed_time:
		_total_tween_time_seconds = displacement_time_seconds
	else:
		_total_tween_time_seconds = distance / trail_velocity_pixels_per_second
	
	# Must be in this order
	rotation = target_position.angle_to_point(start_position)
	
	create_arc_height_tween(arc_height)
	
	_tween.interpolate_method(self, "_update_horizontal_position", _particles.position.x, distance, _total_tween_time_seconds, Tween.TRANS_LINEAR, Tween.EASE_IN)
	
	_tween.start()


func create_arc_height_tween(height: float) -> void:
	_tween.interpolate_method(self, "_update_arc_height", _particles.position.y, height, _total_tween_time_seconds / 2, Tween.TRANS_SINE, Tween.EASE_IN_OUT)


func _update_arc_height(height: float) -> void:
	_particles.position.y = height


func _update_horizontal_position(horizontal_position: float) -> void:
	_particles.position.x = horizontal_position


func _on_Tween_tween_all_completed() -> void:
	emit_signal("target_reached")
	
	_particles.emitting = false
	
	$Timer.start()
	
	yield($Timer, "timeout")
	
	queue_free()


func _on_Tween_tween_completed(_object: Object, key: String) -> void:
	if key == ":_update_arc_height" and is_equal_approx(_particles.position.y, arc_height):
		create_arc_height_tween(0.0)
		
		_tween.start()
