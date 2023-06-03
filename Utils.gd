extends Node


static func disable_object(object: Object) -> void:
	object.set_deferred("disabled", true)


static func enable_object(object: Object) -> void:
	object.set_deferred("disabled", false)
