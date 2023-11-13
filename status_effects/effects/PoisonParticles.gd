extends CPUParticles2D


func stop() -> void:
	emitting = false
	
	$Timer.wait_time = lifetime * 2
	
	$Timer.start()
	
	yield($Timer, "timeout")
	
	queue_free()
