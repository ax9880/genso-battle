extends Node


static func disable_object(object: Object) -> void:
	object.set_deferred("disabled", true)


static func enable_object(object: Object) -> void:
	object.set_deferred("disabled", false)


# Units depend on distance and velocity, but generally it is in seconds
static func calculate_time(start_point: Vector2, end_point: Vector2, velocity: float) -> float:
	return start_point.distance_to(end_point) / velocity
