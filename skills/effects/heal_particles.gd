extends CPUParticles2D


export(bool) var free_on_timeout: bool = true


func play() -> void:
	emitting = true


func _on_Timer_timeout() -> void:
	if free_on_timeout:
		queue_free()
