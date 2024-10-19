extends Node2D


signal target_reached

export(float) var trail_velocity_pixels_per_second := 1200.0
export(float) var displacement_time_seconds := 0.2

# If true, the tween time is fixed and the velocity of the trail will
# be determined by the tween automatically.
export(bool) var is_tween_fixed_time := true

export(float) var arc_height := 100.0

export(NodePath) var particles_node_path: NodePath

var particles: CPUParticles2D
var target: Vector2
var total_tween_time_seconds: float

onready var tween := $Tween


func _ready() -> void:
	 particles = get_node(particles_node_path)


func play(start_position: Vector2, target_position: Vector2) -> void:
	particles.emitting = true
	
	var distance: float = start_position.distance_to(target_position)
	
	if is_tween_fixed_time:
		total_tween_time_seconds = displacement_time_seconds
	else:
		total_tween_time_seconds = distance / trail_velocity_pixels_per_second
	
	# Must be in this order
	rotation = target_position.angle_to_point(start_position)
	
	create_arc_height_tween(arc_height)
	
	tween.interpolate_method(self, "_update_horizontal_position", particles.position.x, distance, total_tween_time_seconds, Tween.TRANS_LINEAR, Tween.EASE_IN)
	
	tween.start()


func create_arc_height_tween(height: float) -> void:
	tween.interpolate_method(self, "_update_arc_height", particles.position.y, height, total_tween_time_seconds / 2, Tween.TRANS_SINE, Tween.EASE_IN_OUT)


func _update_arc_height(height: float) -> void:
	particles.position.y = height


func _update_horizontal_position(horizontal_position: float) -> void:
	particles.position.x = horizontal_position


func _on_Tween_tween_all_completed() -> void:
	emit_signal("target_reached")
	
	particles.emitting = false
	
	$Timer.start()
	
	yield($Timer, "timeout")
	
	queue_free()


func _on_Tween_tween_completed(_object: Object, key: String) -> void:
	if key == ":_update_arc_height" and is_equal_approx(particles.position.y, arc_height):
		create_arc_height_tween(0.0)
		
		tween.start()
