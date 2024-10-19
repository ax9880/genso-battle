extends Area2D


# Returns the unit that owns this area 2D
func get_unit() -> KinematicBody2D:
	return get_parent() as KinematicBody2D
