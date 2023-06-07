extends Node2D

onready var particles: CPUParticles2D = $HealParticles
onready var tween := $Tween

export(float) var trail_velocity_pixels_per_second := 400.0
export(float) var arc_height := 100.0

var target: Vector2
var total_tween_time_seconds: float

signal target_reached

func play(start_position: Vector2, target_position: Vector2) -> void:
	var distance: float = start_position.distance_to(target_position)
	
	total_tween_time_seconds = distance / trail_velocity_pixels_per_second
	
	rotation = start_position.angle_to_point(target_position)
	
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


func _on_Tween_tween_completed(_object: Object, key: String) -> void:
	if key == ":_update_arc_height" and is_equal_approx(particles.position.y, arc_height):
		create_arc_height_tween(0.0)
		
		tween.start()
